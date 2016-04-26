class UsersController < ApplicationController
  before_action :authenticate_user!, :except => :show
  before_action :admin_only, :except => [:show, :index]

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @projects = Project.all
    @do_requests = DoRequest.all
    @assignments = Assignment.all
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(secure_params)
      redirect_to users_path, :notice => "User updated."
      current_user.create_activity(@user, 'updated')
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    current_user.create_activities(@user, 'deleted')
    redirect_to users_path, :notice => "User deleted."
  end

  private

  def admin_only
    unless current_user.admin?
      redirect_to :back, :alert => "Access denied."
    end
  end

  def secure_params
    params.require(:user).permit(:role, :picture, :name, :email, :password)
  end

end
