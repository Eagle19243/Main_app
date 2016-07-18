class VisitorsController < ApplicationController
  before_action :first_project

  def index
  end

  def landing
    @featured_projects = Project.last(3)
  end

  def restricted
  end

  private

  def first_project
    @project = Project.first
  end
end
