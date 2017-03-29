class GroupMessagesController < ApplicationController
  autocomplete :user, :name, :full => true
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_group_message, only: [:show, :edit, :update, :destroy]
  before_action :validate_create_messages_access_for_chatroom, only: [:create]

  layout 'dashboard', only: [:index, :user_messaging]

#-------------------------------------------------------------------------------
# Standard Controller Actions
#-------------------------------------------------------------------------------

  def index
    @user_projects = current_user.get_users_projects_and_team_projects
    if @user_projects.any?
      @chatroom = @user_projects.first.chatrooms.where(user: nil, recipient: nil).first
      @team_members = @chatroom.groupmembers.where.not(user: current_user)
      @group_messages = @chatroom.group_messages
    else
      @group_messages = []
    end
    @one_to_one_chat_users = current_user.all_one_on_one_chat_users
  end

  def show
  end

  def new
    @group_message = GroupMessage.new
  end

  def create
    chatroom = Chatroom.find(params[:group_message][:chatroom_id])
    unless (params[:group_message][:message].blank? && params[:group_message][:attachment].blank?) || chatroom.blank?
      @group_message = chatroom.group_messages.new(group_message_params)
      @group_message.user = current_user
      respond_to do |format|
        if @group_message.save
          format.json { render :show, status: :created, location: @group_message }
          format.js
        else
          format.json { render json: @group_message.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @group_message.update(group_message_params)
        format.json { render :show, status: :ok, location: @group_message }
      else
        format.json { render json: @group_message.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @group_message.destroy
    respond_to do |format|
      format.json { head :no_content }
    end
  end

#-------------------------------------------------------------------------------
# API
#-------------------------------------------------------------------------------

  def get_chatroom

    project = Project.find(params[:project_id]) if params[:project_id].present?
    recipient_user = User.find(params[:user_id]) if params[:user_id].present?

    if project.present? && !recipient_user.present?
      #Project Group Chatroom
      @chatroom = project.chatrooms.where(user: nil, recipient: nil).first
      if @chatroom.present? && @chatroom.validate_access_for(current_user)
        @team_members = @chatroom.groupmembers.where.not(user: current_user)
        @group_messages = @chatroom.group_messages
      end
    elsif project.present? && recipient_user.present?
      #Direct Message to a Project Team Member
      @chatroom = (current_user.chatrooms.where(project: project, recipient: recipient_user) + current_user.chatrooms_where_recipient.where(project: project, user: recipient_user)).first
      if @chatroom.present?
        @group_messages = @chatroom.group_messages
      else
        if current_user.is_team_member_for?(project)
          @chatroom = Chatroom.create_team_member_direct_chatroom(project,current_user,recipient_user)
          @group_messages = []
        end
      end
    elsif !project.present? && recipient_user.present?
      #Direct Message with no Project
      @chatroom = (current_user.chatrooms.where(project: nil, recipient: recipient_user) + current_user.chatrooms_where_recipient.where(project: nil, user: recipient_user)).first
      if @chatroom.present?
        @group_messages = @chatroom.group_messages
      else
        @chatroom = Chatroom.create_direct_chatroom(current_user,recipient_user)
        @group_messages = []
      end
    end

    @one_to_one_chat_users = current_user.all_one_on_one_chat_users

    if @chatroom.present?
      respond_to :js
    else
      redirect_to group_messages_path
    end

  end

  def refresh_chatroom_messages
    if Chatroom.validate_access_from_params(params[:id],current_user)
      @group_messages = GroupMessage.where(chatroom_id: params[:id]).last(25)
      respond_to :js
    end
  end

  def search_user
    @user = current_user
    if params[:search]
      @user = User.name_like("%#{params[:search]}%").order('name')
    else
    end
  end

  def download_files
    group_message = GroupMessage.find(params[:id])
    if load_messages_by_chatroom (group_message.chatroom_id)
      if group_message.attachment.blank?
        redirect_to group_messages_path
      else
        data = open(group_message.attachment.file.url)
        send_data data.read, filename:group_message.attachment.file.filename, stream: 'true'
      end
    else
      redirect_to group_messages_path
    end
  end

#-------------------------------------------------------------------------------

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_group_message
    @group_message = GroupMessage.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def group_message_params
    params.require(:group_message).permit(:message, :user_id, :chatroom_id, :attachment)
  end

  def validate_create_messages_access_for_chatroom
    Chatroom.validate_access_from_params(params['group_message']['chatroom_id'],current_user)
  end

end
