class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def index
    @messages = @conversation.messages
    if @messages.length > 10
      @over_ten = true
      @messages = @messages[-10..-1]
    end

    if params[:m]
      @over_ten = false
      @messages = @conversation.messages
    end

    if @messages.last
      if @messages.last.user_id != current_user.id
        @messages.last.read = true;
      end
    end

    @message = @conversation.messages.new
  end
  
  def new
   @message = @conversation.messages.new
  end
  
  def create
    @message = @conversation.messages.new(message_params)
    respond_to do |format|
      if @message.save 
        format.html {redirect_to conversation_messages_path(@conversation)}
        format.js {}
      else
        format.html {redirect_to :back}
        format.js {}
      end
    end
  end
  
  private
   
  def message_params
    params.require(:message).permit(:body, :user_id, :image)
  end

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

end