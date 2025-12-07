require %#./lib/conversation#

json = File.read '../conversations.json'
$data = Conversation.new_index(JSON.parse json)


conversation_fields = %w{title create_time update_time mapping current_node id}
message_fields = %w{id author create_time update_time content metadata recipient}
content_fields = %w{content_type parts}

$data.map { |ea|
  ea.delete_if { |key, _| !conversation_fields.include? key }
  ea['mapping'].values.each { |m|
    next unless m['message']
    m['message'].delete_if { |key, _| !message_fields.include? key }
    m['message']['content'].delete_if { |key, _| !content_fields.include? key }
    next unless m['message']['content']['parts']
    m['message']['content']['parts'] = m['message']['content']['parts'].grep(String)
  }
}

File.write('../conversations_trimmed.json', $data.to_json)

if ARGV.include? %(-i)
  binding.pry
end