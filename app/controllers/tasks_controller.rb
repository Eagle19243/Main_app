class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  # GET /tasks
  # GET /tasks.json


  # GET /tasks/1
  # GET /tasks/1.json
  def show
    @comments = @task.task_comments.all
    @assignment = Assignment.new

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
    @task = Task.find(params[:id])
    if @task.accept!
      flash[:success] = "Task accepted"
    else flash[:error] = "Task was not accepted"

    end
    redirect_to   taskstab_project_path(@task.project_id)


  end

  def reject
    @task = Task.find(params[:id])
    if @task.reject!
      flash[:success] = "Task Rejected"
    else flash[:error] = "Task was not Rejected "

    end
    redirect_to  taskstab_project_path(@task.project_id)

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = Task.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def task_params
      params.require(:task).permit(:references, :deadline, :target_number_of_participants, :project_id, :short_description, :number_of_participants, :proof_of_execution, :title, :description, :budget, :user_id, :condition_of_execution, :fileone, :filetwo, :filethree, :filefour, :filefive)
    end
end
