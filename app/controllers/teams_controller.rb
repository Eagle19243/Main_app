class TeamsController < ApplicationController
  def users_search
    @project = Project.find(params[:project_id])
    users = User.name_like(params[:search])

    @results = users.select do |user|
      # TODO God does not understand which users should be returned here !
      !user.is_team_admin?(@project.team) && !user.has_pending_admin_requests?(@project) && user.id != @project.user.id
    end
    respond_to do |format|
      format.js
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def team_params
      params.require(:team).permit(:name)
    end
end
