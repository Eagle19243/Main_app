class AssignmentsController < ApplicationController
	def new
		@assignment = Assignment.new

	end

	def create

		 @assignment = Assignment.new(assignment_params)
		if @assignment.save!
			flash[:success] = "Task assigned"

		else
			flash[:error] = "Task was not assigned"
		end
	end


	def destroy

	end

private
def assignment_params
	params.require(:assignment).permit(:task_id, :user_id, :free)
end

end
