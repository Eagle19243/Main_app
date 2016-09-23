class TaskAttachmentsController < ApplicationController
  protect_from_forgery except: :destroy_attachment

  before_action :authenticate_user!
  before_action :validate_attachment, only:[:create]
  def validate_attachment
    task=Task.find(params['task_attachment']['task_id'])
   if ! (task.project.team.team_memberships.collect(&:team_member_id).include? current_user.id || current_user.id == task.project.user_id)
     flash[:error]= " you are not allowed to do this opration "
     redirect_to task_path(task.id)
   end
  #puts ''
  end

  def create
    @task_attachment = TaskAttachment.new(resume_params)
    @task_attachment.user_id=current_user.id
    if @task_attachment.save
      redirect_to task_path(@task_attachment.task_id), notice: "The Task Attachment #{@task_attachment.task_id} has been uploaded."
    else
      render task_path(@task_attachment.task_id)
    end
  end

  def destroy_attachment
    @task_attachment = TaskAttachment.find(params[:id])
    if  @task_attachment.task.project.user_id == current_user.id
      @task_attachment.destroy
      respond_to do |format|
        format.json { render :json => true }
      end

    else
      respond_to do |format|
        format.json { render :json =>false}
      end

    end
  end

  private
  def resume_params
    params.require(:task_attachment).permit(:task_id, :attachment)
  end
end
