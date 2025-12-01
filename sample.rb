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
  def self.extended(enum)
    h = enum.instance_variable_set(:@index, Hash.new)
    enum.each { |each| h[each.id] = each }
  end

  def [](id)
    return super unless String === id
    @index.fetch(id) { raise KeyError, "Index not found: \"#{id}\"" }
  end
end

module Conversation
  def self.new_index(data)
    data.map { |each| each.extend Conversation }.extend Index
  end

  def messages
    unless @messages
      @messages = self['mapping'].values.map { |each| each.extend Message }.extend Index
      @messages.first.fix_root_message
    end
    @messages
  end

  def text_only?
    messages.all?(&:text?)
  end

  def conversation_url
    "https://chatgpt.com/c/#{self.id}"
  end

  def current_node
    messages[self['current_node']]
  end

  def all_nodes
    nodes = [node = current_node]
    nodes << (node = messages[node.parent]) while node.parent
    nodes.reverse
  end

  def hidden_nodes
    self.messages - self.all_nodes
  end

  def summary
    [self.id, self.title]
  end
end

module Message

  ROOT_MESSAGE = {
    'content' => { 'content_type' => "text", 'parts' => [] },
    'author' => { 'role' => 'system' },
  }.freeze

  def fix_root_message
    raise unless self['parent'].nil? && self['message'].nil?
    self['message'] = ROOT_MESSAGE
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
num = (Integer STDIN.gets).pred rescue rand(5)
puts samples[num].conversation_url

# $text.map { |ea| [ea.id, ea.title, ea.all_nodes.sum { |m| m.content.scan(/\S+/).size }] }.sort_by(&:last).reverse


if ARGV.include?('-i')
  require 'pry'
  binding.pry
end