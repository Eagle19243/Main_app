class VisitorsController < ApplicationController
	def index
    @project = Project.find(1)
  end
end
