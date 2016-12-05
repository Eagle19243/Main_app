class VisitorsController < ApplicationController
  before_action :first_project

  def index
  end

  def landing
    if (session[:counter].nil?)
      session[:counter] = 1
      session[:counter] = session[:counter] + 0
    end
    session[:counter] = session[:counter] + 1
    if(session[:counter] > 3000 || user_signed_in?)
      redirect_to home_index_path
    else
      @featured_projects = Project.last(3)
    end
  end

  def restricted
  end

  private

  def first_project
    @project = Project.first
  end
end
