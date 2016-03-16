class DoRequestsController < ApplicationController
  before_filter :authenticate_user!
  

  def index
  end

  def new
    @task = Task.find(params[:task_id])
    @free = params[:free]
    @do_request = DoRequest.new
  
  end

  def create
     @do_request = current_user.do_requests.build(request_params)
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
      format.html { redirect_to current_user, notice: 'Task assignment request was successfully destroyed.' }
      format.json { head :no_content }
    end

  end



  def accept
    @do_request = DoRequest.find(params[:id])
    if @do_request.accept! 
      @do_request.user.assign(@do_request.task, @do_request.free)  
       flash[:success] = "Task has been assigned"
     else
      flash[:error] = "Task was not assigned to user"
       #assign(@do_request.user, @do_request.task, @do_request.free)

    end
  end


  def reject
    @do_request = DoRequest.find(params[:id])
    if @do_request.reject!
      flash[:succes] = "Request rejected"

    else
      flash[:error] = "Was not able to reject request"
    end

  end



  private 

  def request_params
    params.require(:do_request).permit(:application, :task_id, :user_id, :free)
  end
  
end