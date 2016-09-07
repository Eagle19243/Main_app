class DashboardController < ApplicationController
  before_action :authenticate_user!, :except => :show

  def dashboard
    @user = current_user
    @conversations = []
    #if (current_user && current_user.id == @user.id)
      @conversations = Conversation.where("recipient_id = ? OR sender_id = ?", params[:id], params[:id])
      if @conversations.count == 0
        first_user_with_conversations = User.first
        recipient = first_user_with_conversations
        cfirst = Conversation.new(sender_id: current_user.id, recipient_id: recipient.id)
        if cfirst.save
          cfirst.messages.create(body: "A test message", user_id: current_user, read: false)
          @conversations.push(cfirst)
        end
      end
    #end
    @notifications = Notification.last(5)
    @projects = Project.all
    @do_requests = DoRequest.all
    @assignments = Assignment.all
  end
end
