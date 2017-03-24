class TaskAttachmentsController < ApplicationController
  protect_from_forgery except: :destroy_attachment
  protect_from_forgery except: :create

  before_action :authenticate_user!

  def create
    @task_attachment = TaskAttachment.new(resume_params)
    @task_attachment.user_id = current_user.id

    authorize! :create, @task_attachment

    respond_to do |format|
      if @task_attachment.save
        @notice = "The Task Attachment has been uploaded."
        format.html { redirect_to task_path(@task_attachment.task_id), notice: @notice }
        format.js
      else
        @notice = "Failed to uploaded Task Attachment."
        format.html { redirect_to '/', notice: @notice }
        format.js
      end
    end
  end

  def destroy_attachment
    @task_attachment = TaskAttachment.find(params[:id])

    authorize! :destroy, @task_attachment

    if @task_attachment.destroy
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
