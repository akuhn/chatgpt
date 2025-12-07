require './lib/conversation'

json = File.read '../conversations.json'
$data = Conversation.new_index(JSON.parse json)

if ARGV.include?("--len")
  sorted = $data.reject(&:any_dalle?).sort_by { |m| m.messages.size }
else
  sorted = $data.reject(&:any_dalle?).sort_by(&:create_time)
end

ea = sorted[rand * rand * sorted.size]

puts Time.at ea.create_time
p ea.title
puts ea.conversation_url

if ARGV.include?('-i')
  binding.pry
end
