class DoRequestsController < ApplicationController
  before_filter :authenticate_user!

  def index
  end

  def new
    @task = Task.find(params[:task_id])
    if @task.suggested_task?
      flash[:error] = "You can not apply for suggested task "
      redirect_to task_path(@task.id)
    end
    @free = params[:free]
    @do_request = DoRequest.new
  end

  def create
    task = Task.find(request_params[:task_id])
    flash[:error] = 'You can not apply for suggested task' if task.suggested_task?

    @do_request = current_user.do_requests.build(request_params)
    @do_request.project_id = task.project_id
    @do_request.state = 'pending'
    @do_request.state = 'accepted' if current_user.id == task.project.user_id

    respond_to do |format|
      if @do_request.save
        RequestMailer.to_do_task(requester: current_user, task: task).deliver_later

        flash[:notice] = 'Request sent to Project Admin'
        flash[:notice] = 'Your application to perform this task was submitted successfully. The project leader will notify you once it has been received and a decision is made.' if current_user.id == task.project.user_id

        format.js
        format.html { redirect_to @do_request.task }
      else
        flash[:error] = 'You can not apply twice'

        format.js
        format.html { redirect_to root_url }
      end
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
    authorize! :accept, @do_request

    task = @do_request.task
    if current_user.id == @do_request.task.project.user_id
      if @do_request.accept!
        @do_request.user.assign(task, @do_request.free)
        @current_number_of_participants = task.try(:number_of_participants) || 0
        task.update_attribute(:deadline, task.created_at + 60.days)
        task.update_attribute(:number_of_participants, @current_number_of_participants + 1)
        team = Team.find_or_create_by(project_id: @do_request.project_id)
        users_ids = team.team_memberships.collect(&:team_member_id)
        if (!users_ids.include?(@do_request.user_id))
          Chatroom.add_user_to_project_chatroom(@do_request.task.project, @do_request.user)
        end
        membership = TeamMembership.find_or_create_by(team_member_id: @do_request.user_id, team_id: team.id,role: 0)
        #task.team_memberships.add(membership)
        TaskMember.create(task_id: task.id, team_membership_id: membership.id)
        RequestMailer.accept_to_do_task(do_request: @do_request).deliver_later
        flash[:notice] = "Task has been assigned"
      else
        flash[:error] = "Task was not assigned to user"
      end
    else
      flash[:error] = "You Are Not Authorized User"
    end
    redirect_to taskstab_project_path(@do_request.project, tab: 'requests')
  end

  def reject
    @do_request = DoRequest.find(params[:id])
    authorize! :reject, @do_request

    if current_user.id == @do_request.task.project.user_id
      if @do_request.reject!
        RequestMailer.reject_to_do_task(do_request: @do_request).deliver_later
        flash[:notice] = 'Request rejected'
      else
        flash[:error] = "Was not able to reject request"
      end
    else
      flash[:error] = "You Are Not Authorized User"
    end
    redirect_to taskstab_project_path(@do_request.project, tab: 'requests')
  end

  private

  def request_params
    params.require(:do_request).permit(:application, :task_id, :user_id, :free)
  end

end
