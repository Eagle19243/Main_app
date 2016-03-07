class VisitorsController < ApplicationController
	def index
	@projects = Project.all
    end
end
