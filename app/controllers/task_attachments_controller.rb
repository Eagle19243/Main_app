class TaskAttachmentsController < ApplicationController
  protect_from_forgery except: :destroy_attachment
  protect_from_forgery except: :create

  before_action :authenticate_user!
  before_action :validate_attachment, only: [:create]

  def validate_attachment
    @task=Task.find(params['task_attachment']['task_id'])
    @task_memberships = @task.team_memberships
      if !(user_signed_in? && (((current_user.id == @task.project.user_id || (@task.team_memberships.collect(&:team_member_id).include? current_user.id)) && (!@task.suggested_task?)) || ( current_user.id == @task.user_id && @task.suggested_task? )))
      flash[:error] = " you are not allowed to do this opration "
      redirect_to task_path(@task.id)
    end
  end

  def create
    @task_attachment = TaskAttachment.new(resume_params)
    @task_attachment.user_id = current_user.id
    respond_to do |format|
      if @task_attachment.save
        @notice = "The Task Attachment has been uploaded."
        format.html { redirect_to task_path(@task_attachment.task_id), notice: @notice }
        format.js
      else
        @notice = "Failed to uploaded Task Attachment ."
        format.html { redirect_to '/', notice: @notice }
        format.js
      end
    end
  end

  def destroy_attachment
    @task_attachment = TaskAttachment.find(params[:id])
    if user_signed_in? && ((@task_attachment.task.suggested_task? && (current_user.id == @task_attachment.task.user_id ||  current_user.id == @task_attachment.task.project.user_id )) || (@task_attachment.task.is_executer(current_user.id) || current_user.id == @task_attachment.task.project.user_id))
        #if @task_attachment.task.project.user_id == current_user.id
      @task_attachment.destroy
      respond_to do |format|
        format.json { render :json => true }
      end
    else
      respond_to do |format|
        format.json { render :json => false }
      end

    end
  end

  private
  def resume_params
    params.require(:task_attachment).permit(:task_id, :attachment)
  end
end
