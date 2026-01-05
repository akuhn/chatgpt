require './lib/conversation'
require 'options_by_example'

Options = OptionsByExample.read(DATA).parse(ARGV)

json = File.read '../conversations.json'
$data = Conversation.new_index(JSON.parse json)

Options.if_present :match do |word|
  $data = $data.select { |ea| ea.match? word }
end

unless Options.include? :dalle
  $data = $data.reject(&:any_dalle?)
end

if Options.include? :uniform
  ea = $data[rand * $data.size]
elsif Options.include? :message
  messages = $data.flat_map(&:messages)
  messages = messages.sort_by(&:create_time)
  messages = messages.reverse if Options.include? :recent
  ea = messages[rand * rand * messages.length]
else
  if Options.include? :recent
    $data = $data.sort_by(&:create_time).reverse
  elsif Options.include? :short
    $data = $data.sort_by(&:msg_count)
  else
    $data = $data.sort_by(&:create_time)
  end
  ea = $data[rand * rand * $data.size]
end

puts Time.at ea.create_time
p ea.title
puts ea.conversation_url

if Options.include? :interactive
  binding.pry
end


__END__
Selects a conversation at random, with a preference for older conversations

Usage: random [options]

Options:
  -i, --interactive     Open the debugger after the script finishes running
  --dalle               Include conversations with dalle images
  --match WORD          Only consider conversations containing WORD
  --messages            Sort by messages instead of whole conversations
  --recent              Prefer more recent conversations
  --short               Prefer shorter conversations
  --uniform             Select with uniform probability
