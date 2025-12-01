require './lib/conversation'

json = File.read 'conversations.json'

$data = Conversation.new_index(JSON.parse json)

# Choose one of five
samples = $data.reject(&:any_dalle?).shuffle.take(5)
samples.each_with_index do |each, n|
  puts "#{n.succ}) #{each.title}"
end
print "Pick 1-5: "
num = (Integer STDIN.gets).pred rescue rand(5)
puts samples[num].conversation_url

# $text.map { |ea| [ea.id, ea.title, ea.all_nodes.sum { |m| m.content.scan(/\S+/).size }] }.sort_by(&:last).reverse

if ARGV.include?('-i')
  binding.pry
end