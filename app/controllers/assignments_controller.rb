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
		redirect_to @assignment.task
	end




	def accept
		@assignment = Assignment.find(params[:id])
		if @assignment.accept!
			flash[:success] = "Assignment accepted"
		else flash[:error] = "Assignment was not accepted"
			redirect_to dashboard_path
		end

	end



	def reject
		@assignment = Assignment.find(params[:id])
		if @assignment.reject!
			flash[:success] = "Assignment rejected"
		else 
			flash[:error] = "Assignment was not rejected"
			redirect_to dashboard_path
		end
	end


	def destroy

	end

private
def assignment_params
	params.require(:assignment).permit(:task_id, :user_id, :free)
end

end
