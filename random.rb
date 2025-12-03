require './lib/conversation'

json = File.read '../conversations.json'
$data = Conversation.new_index(JSON.parse json)

sorted = $data.reject(&:any_dalle?).sort_by(&:create_time)
ea = sorted[rand * rand * sorted.size]
puts Time.at ea.create_time
p ea.title
puts ea.conversation_url
