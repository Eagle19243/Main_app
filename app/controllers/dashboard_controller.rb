class DashboardController < ApplicationController
  before_action :authenticate_user!, :except => :show

  def dashboard
    @do_requests = DoRequest.all
    @projects = Project.all
    @assignments = Assignment.all
  end
end
