class TaskCommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    task = Task.find(params[:task_id])

    @comment = task.task_comments.build(comment_params)
    @comment.user_id = current_user.id

    authorize! :create, @comment

    respond_to do |format|
      if @comment.save
        set_activity(task, 'created')
        format.html  { redirect_to :back, success: 'Comment submitted'}
        format.js
      else
        format.html  { redirect_to :back, success: 'Error While Saving this comment please comment again' }
        format.js
      end
    end
  end

  private

  def comment_params
    params.require(:task_comment).permit(:body, :attachment, :task_id)
  end

  def set_activity(task = @comment.task, text)
    current_user.create_activity(@comment, text)
  end
end
