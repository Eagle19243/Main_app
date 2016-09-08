class DashboardController < ApplicationController
  before_action :authenticate_user!, :except => :show

  def dashboard
    @user = current_user
  end
end
