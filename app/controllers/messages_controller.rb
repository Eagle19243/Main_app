class MessagesController < ApplicationController
  # before_action do
  #  @conversation = Conversation.find(params[:conversation_id])
  # end
 layout false

 def index
  @projects= current_user.projects.all
 end

  def create_chat_room
  end
end