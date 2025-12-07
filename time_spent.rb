require './lib/conversation'

json = File.read '../conversations.json'
$data = Conversation.new_index(JSON.parse json)

conversations = $data.reject(&:any_dalle?)
conversations.flat_map(&:messages).map { |m| m.dig('message', 'create_time') }

if ARGV.include?('-i')
  binding.pry
end