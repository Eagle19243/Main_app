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
      flash[:success] = "Comment updated"
      redirect_to @comment.task
    else
      render 'edit'
    end
    end

    def destroy
    	TaskComment.find(params[:id]).destroy
        flash[:success] = "Comment deleted"
        redirect_to users_url
    end 

  
  private
    def comment_params
      params.require(:task_comment).permit(:user_id, :body, :task_id)
    end
end
