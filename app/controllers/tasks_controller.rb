class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy, :accept, :reject, :doing]
  before_action :validate_user, only:[:accept, :reject, :doing ]
  before_action :validate_team_member, only:[:reviewing ]
  before_action :validate_admin, only:[:completed ]

  def validate_team_member
  @task= Task.find(params[:id]) rescue nil
  if @task.blank?
    redirect_to '/'
  else
    if ! (@task.project.team.team_memberships.collect(&:team_member_id).include? current_user.id && @task.doing? ) || @task.blank?
      flash[:error]= " you are not allowed to do this opration "
      redirect_to task_path(@task.id)
    end
    end
  end
  def validate_admin
   @task= Task.find(params[:id]) rescue nil
   if @task.blank?
     redirect_to '/'
   else
    if ! (current_user.id == @task.project.user_id && @task.reviewing? )
      flash[:error]= " you are not allowed to do this opration "
      redirect_to '/'#task_path(task.id)
    end
end
  end
  layout false, only: [:show]
  before_action :authenticate_user! ,only: [:send_email, :create,:new , :edit, :destroy, :accept, :reject, :doing, :reviewing,:completed]

  # GET /tasks
  # GET /tasks.json


  # GET /tasks/1
  # GET /tasks/1.json
  def show
    @task_comments = @task.task_comments.all
    #@assignment = Assignment.new

    @task=Task.find(params[:id]) rescue (redirect_to  '/')
    @project=@task.project
    @comments = @project.project_comments.all
    @proj_admins_ids = @project.proj_admins.ids
    @current_user_id = 0
    if user_signed_in?
      @current_user_id = current_user.id
    end
    @followed = false
    @rate = 0
    if user_signed_in?
      @followed = @project.project_users.pluck(:user_id).include? current_user.id
      @current_user_id = current_user.id
      @rate = @project.project_rates.find_by(user_id: @current_user_id).try(:rate).to_i
    end
    @task_attachment=TaskAttachment.new
    @task_attachments=TaskAttachment.where(task_id: @task.id) rescue nil
    @sourcing_tasks = @project.tasks.where(state: ["pending", "accepted"]).all
    @doing_tasks = @project.tasks.where(state: "doing").all
    @suggested_tasks = @project.tasks.where(state: "suggested_task").all
    @reviewing_tasks = @project.tasks.where(state: "reviewing").all
    @done_tasks = @project.tasks.where(state: "done").all

  end

  # GET /tasks/new
  def new
    @project = Project.find(params[:project_id])
    @task =  @project.tasks.build
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
      @task.state='suggested_task'
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

      @task.project_id = Task.find(params[:id]).project_id
      if @task.update(task_params)
        activity = current_user.create_activity(@task, 'edited')
        activity.user_id = current_user.id
        format.html { redirect_to @task, notice: 'Task was successfully updated.' }
        format.json { render :show, status: :ok, location: @task }

      else

        format.html  { render :edit }
        format.json { render json: @task.errors, status: :unprocessable_entity }
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
    if  @task.accept!
      flash[:success] = "Task accepted "

      if previous
       @task.assign_address
      end
    else
      flash[:error] = "Task was not accepted"
    end
    redirect_to   task_path(@task.id)


  end
  def doing
   if @task.suggested_task?
     flash[:error] = "You can't Do this Task"
   else

     if current_user.id == @task.project.user_id && @task.start_doing!
       flash[:success] = "Task Status changed to Doing "
     else
       flash[:error] = "Error in Moving  Task"
     end
   end
    redirect_to  task_path(@task.id)

  end

  def reject

    if  @task.reject!
      flash[:success] = "Task Rejected"
    else flash[:error] = "Task was not Rejected "
    end
    redirect_to  task_path (@task.id)

  end

  def reviewing
    if  @task.begin_review!
      flash[:success] = "Task Submitted for Review"
    else flash[:error] = "Task Was Not  Submitted for Review"
    end
    redirect_to  task_path(@task.id)
  end

  def completed
    if  @task.complete!
      flash[:success] = "Task Completed"
    else flash[:error] = 'Task was not Completed '
    end
    redirect_to  task_path(@task.id)
  end

  def send_email
    InvitationMailer.invite_user( params['email'],current_user.name, Task.find(params['task_id']) ).deliver_later
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
    unless  current_user.id == @task.project.user_id
      flash[:error] = "You are Not authorized  to do this operation "
      redirect_to   taskstab_project_path(@task.project_id)
    end
  end
  # Never trust parameters from the scary internet, only allow the white list through.
  def task_params
    params.require(:task).permit(:references, :deadline, :target_number_of_participants, :project_id, :short_description, :number_of_participants, :proof_of_execution, :title, :description, :budget, :user_id, :condition_of_execution, :fileone, :filetwo, :filethree, :filefour, :filefive)
  end
end
