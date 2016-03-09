class TaskCommentsController < ApplicationController
	def index
    @comments =TaskComment.all.paginate(page: params[:page])
  end

 def show
    @comment = TaskComment.find(params[:id])
    @project = @Comment.project
  end

  def new
  end

 
 def create
   task = Task.find(params[:task_id])
  @comment = task.task_comments.build(comment_params)
  @comment.user_id = current_user.id
  if @comment.save
    activity = current_user.create_activity(@comment, 'created')
    activity.user_id = current_user.id
    flash[:success] = "Comment submitted"
    redirect_to :back
  else
    render 'new'
  end
end
    


   def edit
   	@comment = TaskComment.find(params[:id])
   end

   def update
      
    if @comment.update_attributes(comment_params)
      activity = current_user.create_activity(@comment, 'updated')
      activity.user_id = current_user.id
      flash[:success] = "Comment updated"
      redirect_to @comment.task
      current_user.create_activities(@comment, 'updated')
    else
      render 'edit'
    end
    end

    def destroy
    	TaskComment.find(params[:id]).destroy
      activity = current_user.create_activity(@comment, 'deleted')
      activity.user_id = current_user.id
        flash[:success] = "Comment deleted"
        current_user.create_activities(@comment, 'deleted')
        redirect_to users_url
    end 

  
  private
    def comment_params
      params.require(:task_comment).permit(:user_id, :body, :task_id)
    end
end
