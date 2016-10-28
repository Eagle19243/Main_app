module GroupMessagesHelper

def get_chatroom_name(chatroom_id)
  chat_room = Chatroom.find(chatroom_id)
  unless chat_room.blank?
   if (chat_room.user_id.nil? and chat_room.friend_id.nil?)
      Project.find(chat_room.project_id).title rescue 'Project Title Not Found.'
    else
      User.select(:name).where(id: [chat_room.user_id, chat_room.friend_id]).collect(&:name).inspect rescue 'Direct Messages'
    end
  end
end

end
