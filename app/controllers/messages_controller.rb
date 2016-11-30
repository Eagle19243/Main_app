class MessagesController < ApplicationController
  layout false

  def index
    redirect_to  group_messages_path
  end

  def create_chat_room
  end
end
