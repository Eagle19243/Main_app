include UsersHelper

class UsersController < ApplicationController
  load_and_authorize_resource
  layout "dashboard", only: [:show]

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @profile_comments = @user.profile_comments.limit(3)
  end

  def my_projects
    @user = current_user
  end

  def update
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update_attributes(update_params)
        format.html { 
          current_user.create_activity(@user, 'updated')
          redirect_to(@user, :notice => 'User was successfully updated.')
        }
        format.json { respond_with_bip(@user) }
      else
        redirect_to users_path, :alert => "Unable to update user."
        format.json { respond_with_bip(@user) }
      end
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    current_user.create_activities(@user, 'deleted')
    redirect_to users_path, :notice => "User deleted."
  end

  private

  def update_params
    params.require(:user).permit(:picture, :name, :email, :password, :bio,
    :city, :phone_number, :bio, :facebook_url, :twitter_url,
    :linkedin_url, :picture_cache)
  end

  def secure_params
    params.require(:user).permit(:role, :picture, :name, :email, :password, :bio,
    :city, :phone_number, :bio, :facebook_url, :twitter_url,
    :linkedin_url, :picture_cache)
  end

end
