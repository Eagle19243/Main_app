class TaskAttachmentsController < ApplicationController
  protect_from_forgery except: :destroy_attachment

  before_action :authenticate_user!

  def create
    @task_attachment = TaskAttachment.new(resume_params)

    if @task_attachment.save
      redirect_to task_path(@task_attachment.task_id), notice: "The Task Attachment #{@task_attachment.task_id} has been uploaded."
    else
      render task_path(@task_attachment.task_id)
    end
  end

  def destroy_attachment
    @task_attachment = TaskAttachment.find(params[:id])
    if  @task_attachment.user_id == current_user.id
      #Task.find(@task_attachment.id).project.user_id   || current_user.id == @task_attachment.task.project.user_id ||
      ids=@task_attachment.task_id
      @task_attachment.destroy
      "The Task Attachment  has been deleted."
    else
        "Invlid Opration "
    end
  end

  private
  def resume_params
    params.require(:task_attachment).permit(:task_id, :attachment)
  end
end
