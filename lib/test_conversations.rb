require './lib/conversation'
require 'binding_of_caller'

json = File.read '../conversations.json'

class Object
  def raise (*args)
    Object.remove_method :raise
    (binding.of_caller 1).pry
  end
end

$data = Conversation.new_index(JSON.parse json)
$messages = $data.flat_map(&:messages)

raise unless Index === $data

$data.each do |each|
  raise unless Conversation === each
  raise unless each == $data[each.id]
end

$messages.each do |m|
  raise unless Message === m
  raise unless String === m.content_type
  raise unless String === m.content
  # Some more smoke tests...
  m.dalle?
  m.text?
end

binding.pry if ARGV.include? %(-i)

