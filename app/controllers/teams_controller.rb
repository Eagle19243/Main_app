class TeamsController < ApplicationController
  def users_search
    @project = Project.find(params[:project_id])
    search = Sunspot.search(User) do
      fulltext params[:search]
    end
    users = search.results

    @results = users.select do |user|
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
