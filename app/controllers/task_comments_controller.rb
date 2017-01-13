class TaskCommentsController < ApplicationController
  before_action :current_task_comment, only: [:show, :edit, :destroy]

  def index
    @comments = TaskComment.all.paginate(page: params[:page])
  end

  def show
    @project = @Comment.project
  end

  def new
  end
 
  def create
    task = Task.find(params[:task_id])
    @comment = task.task_comments.build(comment_params)
    @comment.user_id = current_user.id
    respond_to do |format|
        if @comment.save
          set_activity(task, 'created')
          format.html  { redirect_to :back, success: 'Comment submitted'}
          format.js
        else
          format.html  { redirect_to :back, success: 'Error While Saving this comment please comment again' }
          format.js = "Error while saving "
        end

    end
  end
    
  def edit
  end

  def update
    if @comment.update_attributes(comment_params)
      set_activity('updated')
      flash[:success] = 'Comment updated'
      redirect_to @comment.task
      current_user.create_activities(@comment, 'updated')
    else
      render :edit
    end
  end

  def destroy
    @comment.destroy
    set_activity('deleted')
    flash[:success] = 'Comment deleted'
    current_user.create_activities(@comment, 'deleted')
    redirect_to users_path
  end 
  
  private

  def comment_params
    params.require(:task_comment).permit(:user_id, :body, :attachment, :task_id)
  end

  def current_task_comment
    @comment = TaskComment.find(params[:id])
  end

  def set_activity(task = @comment.task, text)
    current_user.create_activity(@comment, text)
  end
end
