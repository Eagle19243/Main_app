class FavoriteProjectsController < ApplicationController
  before_filter :authenticate_user!

  def create
    favorite_project = FavoriteProject.new(request_params)
    if current_user.id == favorite_project.user_id && favorite_project.save
      flash[:notice] = "Added to favorites."
    else
      flash[:error] = "Sorry, can not add to favorites."
    end
    redirect_to project_path(request_params[:project_id])
  end

  def destroy
    favorite_project = FavoriteProject.find_by(user_id: request_params[:user_id], 
                                                project_id: request_params[:project_id])
    if current_user.id == favorite_project.user_id && 
        favorite_project && favorite_project.destroy
      flash[:notice] = "Removed from favorites."
    else
      flash[:error] = "Sorry, can not remove from favorites."
    end
    redirect_to project_path(request_params[:project_id])
  end

  private 
  
  def request_params
    params.require(:favorite_project).permit(:project_id, :user_id)
  end
end
