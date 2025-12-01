require 'json'

class Binding
  def pry
    require 'pry'
    super
  end
end

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
      @messages = self['mapping'].values.each { |each| each.extend Message }.extend Index
      @messages.each { |each| each['conversation'] = self.id }
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
      raise if parts.length > 1
      parts.first or ""
    when "multimodal_text"
      parts = self.dig('message', 'content', 'parts')
      content = String === parts.last ? parts.pop : nil
      raise unless parts.all? { |each| each['content_type'] == 'image_asset_pointer' }
      content or ""
    when "thoughts"
      thoughts = self.dig('message', 'content', 'thoughts')
      %(what the heck is thoughts)
    when "reasoning_recap"
      self.dig('message', 'content', 'content')
    when "code", "execution_output", "system_error"
      self.dig('message', 'content', 'text')
    else
      raise
    end
  end
end