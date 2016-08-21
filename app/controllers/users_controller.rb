include UsersHelper

class UsersController < ApplicationController
  layout "application2", only: [:profile]
  before_action :authenticate_user!, :except => :show
  before_action :admin_only, :except => [:show, :index]

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @conversations = []
    #if (current_user && current_user.id == @user.id)
      @conversations = Conversation.where("recipient_id = ? OR sender_id = ?", params[:id], params[:id])
      if @conversations.count == 0
        first_user_with_conversations = User.find(Conversation.first.recipient_id)
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

  def profile
    @user = User.find(params[:id])
    @projects = Project.all
    @do_requests = DoRequest.all
    @assignments = Assignment.all
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(secure_params)
      redirect_to users_path, :notice => "User updated."
      current_user.create_activity(@user, 'updated')
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    current_user.create_activities(@user, 'deleted')
    redirect_to users_path, :notice => "User deleted."
  end

  private

  def admin_only
    unless current_user.admin?
      redirect_to :back, :alert => "Access denied."
    end
  end

  def secure_params
    params.require(:user).permit(:role, :picture, :name, :email, :password, :bio,
    :city, :phone_number, :bio, :facebook_url, :twitter_url,
    :linkedin_url, {:institution_ids => [] }, :picture_cache)
  end

end
