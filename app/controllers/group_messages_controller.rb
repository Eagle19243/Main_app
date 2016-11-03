class GroupMessagesController < ApplicationController
#  require 'GroupMessagesHelper'
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_group_message, only: [:show, :edit, :update, :destroy]
  before_action :validate_chat_room_users, only: [:create]

  def validate_user_messages_by_project(id)
    user_ids = Project.find(id).team.team_memberships.collect(&:team_member_id)
    if !(user_ids.include? current_user.id)
      return false
    end
    return true
  end

  def load_messages_by_chatroom(id)
    chat_room = Chatroom.find(id) rescue nil
    project = Project.find(chat_room.project_id) rescue nil
    if chat_room.blank? || project.blank? || !(chat_room.user_id == current_user.id || chat_room.friend_id == current_user.id || (project.team.team_memberships.collect(&:team_member_id).include? current_user.id))
      return false
    end
    return true
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
      @team_members = @user_projects.first.team.team_memberships
      chatroom = Chatroom.where(project_id: pid1)
      @group_messages = GroupMessage.where(chatroom_id: chatroom.first.id)
      @chatroom = chatroom.first.id
    end
  end

  def show
  end

  # GET /group_messages/new
  def new
    @group_message = GroupMessage.new
  end

  # GET /group_messages/1/edit
  def edit
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

  def get_messages_by_room
    if validate_user_messages_by_project (params[:id])
      chatroom = Chatroom.where(project_id: params[:id])
      @team_members = Team.where(project_id: params[:id]).first.team_memberships
      @group_messages = GroupMessage.where(chatroom_id: chatroom.first.id)
      @chatroom = chatroom.first.id
      respond_to :js
    end
  end

  def load_group_messages
    if load_messages_by_chatroom(params[:id])
      @group_messages = GroupMessage.where(chatroom_id: params[:id]).last(10)
      respond_to :js
    end
  end

  # POST /group_messages
  # POST /group_messages.json
  def create
    @group_message = GroupMessage.new(group_message_params)
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
    params.require(:group_message).permit(:message, :user_id, :chatroom_id)
  end

end
