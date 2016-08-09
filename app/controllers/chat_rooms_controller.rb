class ChatRoomsController < ApplicationController
  def create_room
    if ChatRoom.find_by(project_id: params['project_id']).blank?
    project_id =params['project_id']
    room_id =params['room_id' ]
      res=ChatRoom.create(project_id: project_id ,room_id: room_id) rescue nil
    if res.blank?
      return false
    end
    return true
    end
    return false
  end
end
