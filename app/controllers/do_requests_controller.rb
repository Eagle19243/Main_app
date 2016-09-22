class DoRequestsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
  end

  def new
    @task = Task.find(params[:task_id])
    if @task.suggested_task?
      flash[:error] = "You can not Apply For Suggested Task "
      redirect_to task_path(@task.id)
    end
    @free = params[:free]
    @do_request = DoRequest.new

  end

  def create
     @do_request = current_user.do_requests.build(request_params)
     task=Task.find (request_params['task_id'])
     @do_request.project_id =   task.project_id
     @do_request.state='pending'
      if @do_request.save
        flash[:success] = "Request sent to Project Admin"
        redirect_to @do_request.task
  else

    flash[:error] = "You cannot apply twice"
    redirect_to root_url
  end
  end



  def update
  end


  def destroy
    @do_request = DoRequest.find(params[:id])
     @do_request.destroy
    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: 'Task assignment request was successfully destroyed.' }
      format.json { head :no_content }
    end

  end



  def accept
    @do_request = DoRequest.find(params[:id])
    if @do_request.accept!
      @do_request.user.assign(@do_request.task, @do_request.free)
      @current_number_of_participants = @do_request.task.try(:number_of_participants) || 0
      @do_request.task.update_attribute(:deadline, @do_request.task.created_at + 60.days )
      @do_request.task.update_attribute(:current_number_of_participants, @current_number_of_participants + 1)

       flash[:success] = "Task has been assigned"

     else
      flash[:error] = "Task was not assigned to user"
       #assign(@do_request.user, @do_request.task, @do_request.free)

    end
    redirect_to @do_request.task
  end


  def reject
    @do_request = DoRequest.find(params[:id])
    if @do_request.reject!
      flash[:succes] = "Request rejected"

    else
      flash[:error] = "Was not able to reject request"
    end
    redirect_to @do_request.task

  end



  private


  def request_params
    params.require(:do_request).permit(:application, :task_id, :user_id, :free)
  end

end
