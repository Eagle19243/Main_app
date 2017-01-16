class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy, :accept, :reject, :doing, :task_fund_info, :removeMember]
  before_action :validate_user, only: [:accept, :reject, :doing]
  before_action :validate_team_member, only: [:reviewing]
  before_action :validate_admin, only: [:completed]
  protect_from_forgery :except => :update
  before_action :authenticate_user!, only: [:send_email, :create, :new, :edit, :destroy, :accept, :reject, :doing, :reviewing, :completed]
  include ApplicationHelper


  def validate_team_member
    @task= Task.find(params[:id]) rescue nil
    @task_memberships = @task.team_memberships
    if !(@task.doing? && (@task_memberships.collect(&:team_member_id).include? current_user.id))
      @notice = " you are not allowed to do this opration "
      respond_to do |format|
        format.js
        format.html { redirect_to task_path(@task.id), notice: @notice }
      end
    end
  end

  def validate_admin
    @task = Task.find(params[:id]) rescue nil
    if @task.blank?
      redirect_to '/'
    else
      if !(current_user.id == @task.project.user_id && @task.reviewing?)
        @notice = " you are not allowed to do this opration "
        respond_to do |format|
          format.js
          format.html { redirect_to task_path(@task.id), notice: @notice }
        end
      end
    end
  end

  def get_revision_histories project
    result = project.get_history
    @histories = []

    if result
      result.each do |r|
        history                = Hash.new
        history["revision_id"] = r["id"]
        history["datetime"]    = DateTime.strptime(r["timestamp"],"%s").strftime("%l:%M %p %^b %d, %Y")
        history["user"]        = User.find_by_username(r["author"][0].downcase+r["author"][1..-1]) || User.find_by_username(r["author"])
        history["status"]      = r['status']
        history["comment"]     = r['comment']
        history["username"]    = r["author"]
        history["is_blocked"]  = r["is_blocked"]

        @histories.push(history)
      end
      return @histories
    else
      return []
    end
  end

  def show
   # @task = Task.find(params[:id])
    @project = @task.project
    @comments = @project.project_comments.all
    @proj_admins_ids = @project.proj_admins.ids
    @current_user_id = 0
    @followed = false
    @rate = 0
    if user_signed_in?
      @followed = @project.project_users.pluck(:user_id).include? current_user.id
      @current_user_id = current_user.id
      @rate = @project.project_rates.find_by(user_id: @current_user_id).try(:rate).to_i
    end
    tasks = @project.tasks.all
    @tasks_count =tasks.count
    @sourcing_tasks = tasks.where(state: ["pending", "accepted"]).all
    @done_tasks = tasks.where(state: "completed").count
    @contents = ''
    @is_blocked = 0
    if current_user
      result = @project.page_read current_user.username
    else
      result = @project.page_read nil
    end
    if result
      if result["status"] == 'success'
        @contents = result["html"]
        @is_blocked = result["is_blocked"]
      end
    end

    @histories = get_revision_histories @project

    @mediawiki_api_base_url = Project.load_mediawiki_api_base_url

    @apply_requests = @project.apply_requests.pending.all
    @task_comments = @task.task_comments
    @task_attachment = TaskAttachment.new
    @task_attachments = @task.task_attachments
    @task_memberships = @task.team_memberships
    task_comment_ids = @task.task_comments.collect(&:id)
    @activities = Activity.where("(targetable_type= ? AND targetable_id=?) OR (targetable_type= ? AND targetable_id IN (?))", "Task", @task.id, "TaskComment", task_comment_ids).order('created_at DESC')
  #  project_admin
  #  redirect_to taskstab_project_path(@task.project.id)
  end

  # GET /tasks/new
  def new
    @project = Project.find(params[:project_id])
    @task = @project.tasks.build
  end

  # GET /tasks/1/edit
  def edit
    @project = Task.find(params[:id]).project
  end

  # POST /tasks
  # POST /tasks.json
  def create
    @task = Task.new(task_params)
    @task.user_id = current_user.id
    if @task.project.user_id == current_user.id
      @task.state = 'accepted'
    else
      @task.state = 'suggested_task'
    end
    respond_to do |format|
      if @task.save
        unless @task.suggested_task?
          @task.assign_address
        end
        current_user.create_activity(@task, 'created')

        format.html { redirect_to @task, notice: 'Task was successfully created.' }
        format.json { render :show, status: :created, location: @task }
      else
        format.html { render :new }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end


  def task_fund_info
   if @task.wallet_address.blank?
     @task.assign_address
   end
    respond_to do |format|
    #  format.json { render json: {user_name: current_user.name, wallet_address: @task.wallet_address.sender_address, balance: curent_bts_to_usd(@task.id), status: 200} }
       format.json { render json: { wallet_address: @task.wallet_address.sender_address, balance:curent_bts_to_usd( @task.id ), task_id: @task.id, project_id: @task.project_id , status: 200} }
    end
  end

  # PATCH/PUT /tasks/1
  # PATCH/PUT /tasks/1.json
  def update
    respond_to do |format|
      @task_memberships = @task.team_memberships
      if user_signed_in? && (((current_user.id == @task.project.user_id || (@task_memberships.collect(&:team_member_id).include? current_user.id)) && (@task.pending? || @task.accepted?)) || (current_user.id == @task.user_id && @task.suggested_task?))
        if @task.update(task_params)
          activity = current_user.create_activity(@task, 'edited')
          format.html { redirect_to @task, notice: 'Task was successfully updated.' }
          format.json { render :show, status: :ok, location: @task }
          format.js
        else
          format.html { render :edit }
          format.json { render json: @task.errors, status: :unprocessable_entity }
          format.js
        end
      else
        redirect_to "/"
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.json
  def destroy
    project= @task.project
    if (@task.accepted? || @task.pending?)&& (@task.is_leader(current_user.id) || current_user.id == project.user_id)
      @task.destroy
      respond_to do |format|
        activity = current_user.create_activity(@task, 'deleted')
        activity.user_id = current_user.id
        format.html { redirect_to project_path(project), notice: 'Task was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      format.html { redirect_to project_path(project), notice: 'You can\'t delete this thas' }
    end
  end

  def accept
    previous = @task.suggested_task?
    if @task.accept!
      @notice = "Task accepted "
      if previous
        @task.assign_address
      end
    else
      @notice = "Task was not accepted"
    end
    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), notice: @notice }
    end
  end

  def doing
    if @task.suggested_task?
      @notice = "You can't Do this Task"
    else
      if (current_user.id == @task.project.user_id || @task.is_executer(current_user.id)) && @task.start_doing!
        @notice = "Task Status changed to Doing "
      else
        @notice = "Error in Moving  Task"
      end
    end
    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), notice: @notice }
    end
  end

  def reject
    if @task.reject!
      @notice = "Task Rejected"
      @task.destroy
    else
      @notice = "Task was not Rejected "
    end
    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), notice: @notice }
    end
  end

  def reviewing
    if @task.begin_review!
      @notice = "Task Submitted for Review"
    else
      @notice = "Task Was Not  Submitted for Review"
    end
    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), notice: @notice }
    end
  end

  def completed
    if @task.complete!
      @notice = "Task Completed"
      @task.transfer_task_funds
    else
      @notice = 'Task was not Completed '
    end
    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), notice: @notice }
    end
  end

  def send_email
    InvitationMailer.invite_user(params['email'], current_user.name, Task.find(params['task_id'])).deliver_later
    flash[:success] = "Task link has been send to #{params[:email]}"
    redirect_to task_path(params['task_id'])
  end

  def removeMember
    @team_membership = TeamMembership.find(params[:team_membership_id])
    respond_to do |format|
      if @task.team_memberships.destroy(@team_membership)
        format.json { render json: @team_membership.id, status: :ok }
      else
        format.json { render status: :internal_server_error }
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_task
    @task = Task.find(params[:id]) rescue nil
  end

  def validate_user
    unless current_user.id == @task.project.user_id
      flash[:error] = "You are Not authorized  to do this operation "
      redirect_to taskstab_project_path(@task.project_id)
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def task_params
    params.require(:task).permit(:references, :deadline, :target_number_of_participants, :project_id, :short_description, :number_of_participants, :proof_of_execution, :title, :description, :budget, :user_id, :condition_of_execution, :fileone, :filetwo, :filethree, :filefour, :filefive)
  end
end
