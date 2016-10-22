json.extract! groupmessage, :id, :messgae, :Groupmember_id, :Chatroom_id, :Project_id, :created_at, :updated_at
json.url groupmessage_url(groupmessage, format: :json)