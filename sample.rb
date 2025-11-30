require 'json'

json = File.read 'conversations.json'


class Hash
  def method_missing(sym, *args)
    fetch(sym.to_s) { super }
  end
end

module Enumerable
  def where(patterns)
    find_all { |each| patterns.all? { |sym, pattern| pattern === each.send(sym) }}
  end

  def freq
    h = Hash.new(0)
    if block_given?
      each { |each| h[yield each] += 1 }
    else
      each { |each| h[each] += 1 }
    end
    h.sort_by(&:last).reverse.to_h
  end
end

module Index
  def [](id)
    case id
    when String
      @index ||= each_with_object({}) { |each, h| h[each.id] = each }
      @index.fetch(id) { raise KeyError, "Index not found: \"#{id}\"" }
    else
      super
    end
  end
end

class Conversation < Hash
  attr_reader :messages

  def self.new_index(data)
    data.map { |each| Conversation.new(each) }.extend Index
  end

  def initialize(hash)
    update(hash)
    @messages = self['mapping'].values.map { |each| Message.new(each) }
    raise unless @messages.shift.message.nil?
  end

  def text_only?
    messages.all?(&:text?)
  end

  def conversation_url
    "https://chatgpt.com/c/#{self.id}"
  end
end

class Message < Hash
  def initialize(hash)
    update(hash)
  end

  def root?
    self['parent'].nil?
  end

  def content_type
    self.dig('message', 'content', 'content_type')
  end

  def author_role
    self.dig('message', 'author', 'role')
  end

  def author_name
    self.dig('message', 'author', 'name')
  end

  def text?
    self.content_type == "text"
  end

  def content
    case content_type
    when "text"
      parts = self.dig('message', 'content', 'parts')
      parts and parts.first or ""
    else
      raise
    end
  end
end

$data = Conversation.new_index(JSON.parse json)
$text = $data.select(&:text_only?).extend Index

# Choose one of five
samples = $data.select(&:text_only?).shuffle.take(5)
samples.each_with_index do |each, n|
  puts "#{n.succ}) #{each.title}"
end
print "Pick 1-5: "
num = (Integer STDIN.gets).pred
puts samples[num].conversation_url

if ARGV.include?('-i')
  require 'pry'
  binding.pry
end