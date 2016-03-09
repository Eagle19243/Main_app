class ActivitiesController < ApplicationController
  def index
  	@activities = Activity.order("created_at desc").all
  end
end
