class DashboardController < ApplicationController
  before_action :authenticate_user!, :except => :show

  def dashboard
    @user = current_user
    @profile_comments = @user.profile_comments.page(params[:page]).per(2)
  end
end
