class ProjectCommentsController < ApplicationController
	def index
    @comments =ProjectComment.all.paginate(page: params[:page])
  end

 def show
    @comment = ProjectComment.find(params[:id])
    @project = @Comment.project
  end

  def new
  end

 
 def create
   project = Project.find(params[:project_id])
  @comment = project.project_comments.build(comment_params)
  @comment.user_id = current_user.id
  
  if @comment.save
    flash[:success] = "Your comment has been submitted"
    redirect_to :back
  else
    render 'new'
  end
end
    


   def edit
   	@comment = ProjectComment.find(params[:id])
   end

   def update
      
    if @comment.update_attributes(comment_params)
      flash[:success] = "Comment updated"
      redirect_to @comment.project
    else
      render 'edit'
    end
    end

    def destroy
    	ProjectComment.find(params[:id]).destroy
        flash[:success] = "Comment deleted"
        redirect_to users_url
    end 

  
  private
    def comment_params
      params.require(:project_comment).permit(:user_id, :body, :project_id)
    end
end
