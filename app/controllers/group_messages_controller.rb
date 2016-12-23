class GroupMessagesController < ApplicationController
#  require 'GroupMessagesHelper'
  autocomplete :user, :name, :full => true
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_group_message, only: [:show, :edit, :update, :destroy]
  before_action :validate_chat_room_users, only: [:create]

  layout 'dashboard', only: [:index, :user_messaging]

  def validate_user_messages_by_project(id)
    # user_ids = Project.find(id).team.team_memberships.collect(&:team_member_id)
    user_ids = Project.find(id).chatroom.groupmembers.collect(&:user_id)
    if !(user_ids.include? current_user.id)
      return false
    end
    return true
  end

  def search_user

    @user = current_user
    if params[:search]
      @user = User.name_like("%#{params[:search]}%").order('name')
    else
    end
  end

  def load_messages_by_chatroom(id)
    chat_room = Chatroom.find(id) rescue nil
    project = Project.find(chat_room.project_id) rescue nil
    if project.blank?
      if chat_room.user_id == current_user.id || chat_room.friend_id == current_user.id
        return true
      end
      return false
    else
      if chat_room.blank? || !(chat_room.user_id == current_user.id || chat_room.friend_id == current_user.id || (chat_room.groupmembers.collect(&:user_id).include? current_user.id))
        return false
      end
      return true
    end
  end

  def validate_chat_room_users
    return if !load_messages_by_chatroom(params['group_message']['chatroom_id'])
  end

  def index
    user_teams_id = current_user.team_memberships.collect(&:team_id)
    user_project_ids = Team.find(user_teams_id).collect(&:project_id)
    @user_projects = Project.find (user_project_ids)
    @user_projects = @user_projects + current_user.projects
    if @user_projects.blank?
      @group_messages = []
    else
      @user_projects = @user_projects.uniq
      pid1 = @user_projects.first.id
      chatroom = Chatroom.where(project_id: pid1)
      @team_members = chatroom.first.groupmembers
      @group_messages = GroupMessage.where(chatroom_id: chatroom.first.id)
      @chatroom = chatroom.first.id
    end
    one_to_one_chatrooms = Chatroom.where("project_id is NULL AND ( (user_id = ? OR friend_id = ? ) )", current_user.id, current_user.id)
    ids = one_to_one_chatrooms.collect(&:user_id)
    ids = ids + one_to_one_chatrooms.collect(&:friend_id)
    ids = ids.uniq
    @one_to_one_chat_users = User.find(ids)
  end

  def show
  end

  def user_messaging

    user = User.find(params[:user_id]) rescue nil
    if user.blank?
      redirect_to group_messages_path
    else
      user_id = params[:user_id]
      chatroom = Chatroom.where("project_id is NULL AND ( (user_id = ? AND friend_id = ? ) OR ( user_id = ? AND friend_id = ?  ) )", current_user.id, user_id, user_id, current_user.id) rescue nil
      if chatroom.blank?
        chat= Chatroom.create(user_id: user_id, friend_id: current_user.id)
        #Groupmember.create(chatroom_id: chat.id, user_id: current_user.id)
        #Groupmember.create(chatroom_id: chat.id, user_id: user_id)
        @chatroom = chat.id
      else
        @chatroom = chatroom.first.id
      end
      user_teams_id = current_user.team_memberships.collect(&:team_id)
      user_project_ids = Team.find(user_teams_id).collect(&:project_id)
      @user_projects = Project.find (user_project_ids)
      if @user_projects.blank?
        @group_messages = []
      else
        @user_projects = @user_projects.uniq
        pid1 = @user_projects.first.id
        chatroom = Chatroom.where(project_id: pid1)
        @team_members = chatroom.first.groupmembers

      end
      @group_messages = GroupMessage.where(chatroom_id: @chatroom)
      one_to_one_chatrooms = Chatroom.where("project_id is NULL AND ( (user_id = ? OR friend_id = ? ) )", current_user.id, current_user.id)
      ids = one_to_one_chatrooms.collect(&:user_id)
      ids = ids + one_to_one_chatrooms.collect(&:friend_id)
      ids = ids.uniq
      @one_to_one_chat_users = User.find(ids)
      render :index
    end


  end

  # GET /group_messages/new
  def one_to_one_chat
    user_id = params[:user_id]
    chatroom = Chatroom.where("project_id is NULL AND ( (user_id = ? AND friend_id = ? ) OR ( user_id = ? AND friend_id = ?  ) )", current_user.id, user_id, user_id, current_user.id) rescue nil
    if chatroom.blank?
      chat= Chatroom.create(user_id: user_id, friend_id: current_user.id)
      Groupmember.create(chatroom_id: chat.id, user_id: current_user.id)
      Groupmember.create(chatroom_id: chat.id, user_id: user_id)
      @chatroom = chat.id
    else
      @chatroom = chatroom.first.id
    end
    @group_messages = GroupMessage.where(chatroom_id: @chatroom)
    respond_to :js
  end

  def users_chat
    user_id = params[:user_id]
    project_id = params[:project_id]
    if validate_user_messages_by_project(project_id)
      chatroom = Chatroom.where("project_id = ? AND ( (user_id = ? AND friend_id = ? ) OR ( user_id = ? AND friend_id = ?  ) )", project_id, current_user.id, user_id, user_id, current_user.id) rescue nil
      if chatroom.blank?
        chat=Chatroom.create(project_id: project_id, user_id: user_id, friend_id: current_user.id)

        @chatroom = chat.id
      else
        @chatroom = chatroom.first.id
      end
      @group_messages = GroupMessage.where(chatroom_id: @chatroom)
      respond_to :js
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
       # redirect_to group_message.attachment.file.url
       # send_file group_message.attachment.to_s
      end
    else
      redirect_to group_messages_path
    end
  end

  def get_messages_by_room
    if validate_user_messages_by_project (params[:id])
      chatroom = Chatroom.where(project_id: params[:id])
      @team_members = chatroom.first.groupmembers
      @group_messages = GroupMessage.where(chatroom_id: chatroom.first.id)
      @chatroom = chatroom.first.id
      respond_to :js
    end
  end

  def load_group_messages
    if load_messages_by_chatroom(params[:id])
      @group_messages = GroupMessage.where(chatroom_id: params[:id]).last(25)
      respond_to :js
    end
  end

  def new
    @group_message = GroupMessage.new
  end

  # GET /group_messages/1/edit
  def edit
  end

  def create
    @group_message = GroupMessage.new(group_message_params)
    if (@group_message.message.blank? && @group_message.attachment.blank?)
      @group_message = nil
    else
      @group_message.user_id = current_user.id
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

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_group_message
    @group_message = GroupMessage.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def group_message_params
    params.require(:group_message).permit(:message, :user_id, :chatroom_id, :attachment)
  end

end
