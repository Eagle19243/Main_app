class VisitorsController < ApplicationController
	def index
    @project = Project.find_by(id: 1)
  end

	def restricted
		@project = Project.find_by(id: 1)
	end
end
