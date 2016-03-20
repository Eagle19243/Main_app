class VisitorsController < ApplicationController
	def index
	@projects = Project.all
    end



    def dashboard
    	@do_requests = DoRequest.all
    	@projects = Project.all
    	@assignments = Assignment.all

    end
end
