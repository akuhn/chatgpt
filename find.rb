require './lib/conversation'

json = File.read '../conversations.json'
$data = Conversation.new_index(JSON.parse json)

def find(pattern)
  $data.select { |each| each.match? pattern }
end

matches = find ARGV.first
matches.sort_by(&:create_time).each { |each|
  p [
    each.id,
    (Time.at each.create_time).to_s[0,10],
    each.messages.map(&:content).join(' ').split(/\s+/).size,
    each.title,
  ]
}

binding.pry if ARGV.include?('-i')
