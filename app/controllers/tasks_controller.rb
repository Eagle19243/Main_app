class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy, :accept, :reject, :doing]
  before_action :validate_user, only: [:accept, :reject, :doing]
  before_action :validate_team_member, only: [:reviewing]
  before_action :validate_admin, only: [:completed]
  protect_from_forgery :except => :update

  def validate_team_member
    @task= Task.find(params[:id]) rescue nil
    if @task.blank?
      redirect_to '/'
    else
      @task_team=TeamMembership.where(task_id: @task.id)
      if !(  @task.doing? && (@task_team.collect(&:team_member_id).include? current_user.id) )
       @notice = " you are not allowed to do this opration "
       respond_to do |format|
         format.js
         format.html { redirect_to task_path(@task.id), notice: @notice }
       end
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

  layout false, only: [:show]
  before_action :authenticate_user!, only: [:send_email, :create, :new, :edit, :destroy, :accept, :reject, :doing, :reviewing, :completed]

  def show
    redirect_to taskstab_project_path(@task.project.id)
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
    if @task.project.user_id != current_user.id
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

  # PATCH/PUT /tasks/1
  # PATCH/PUT /tasks/1.json
  def update
    respond_to do |format|
      @task_team=TeamMembership.where(task_id: @task.id)
       if user_signed_in? && (((current_user.id == @task.project.user_id || ( @task_team.collect(&:team_member_id).include? current_user.id)) && ( @task.pending? || @task.accepted?)) || ( current_user.id == @task.user_id && @task.suggested_task? ))
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
    @task.destroy
    respond_to do |format|
      activity = current_user.create_activity(@task, 'deleted')
      activity.user_id = current_user.id
      format.html { redirect_to tasks_url, notice: 'Task was successfully destroyed.' }
      format.json { head :no_content }
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
      if current_user.id == @task.project.user_id && @task.start_doing!
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

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_task
    @task = Task.find(params[:id]) rescue nil
    if @task.blank?
      redirect_to '/'
    end
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
