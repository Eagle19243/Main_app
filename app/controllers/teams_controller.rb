class TeamsController < ApplicationController

  def remove_membership
    @team = TeamMembership.find(params[:id]) rescue nil
    @project_admin = TeamMembership.where("team_id = ? AND state = ?", @team.team_id, 'admin').collect(&:team_member_id) rescue nil
    if (current_user.id == @team.team.project.user_id && @team.destroy)
      @notice='Team member  was successfully Removed.'
    else
      if (@project_admin.include? current_user.id)
        if @team.state == "admin"
          @notice='You can\'t remove admin.'
        else
          if @team.destroy
            @notice='Team member  was successfully Removed.'
          else
            @notice="You can't remove Team Member"
          end
        end
      end
    end
    respond_to do |format|
      format.html { redirect_to teams_url, notice: 'Team member  was successfully destroyed.' }
      format.json { head :no_content }
      format.js
    end

  end

  def team_memberships
    @project = Project.find(params[:project_id])
    @team = @project.team
    if @team.nil?
      @project_team = @project.create_team(name: "Team#{project.id}")
      @project_team.save
      first_member = TeamMembership.create(team_member_id: @project.user_id, team_id: @project_team.id)
      first_member.save
    end
    @project_team = Team.where(project_id: @project.id).first
    @add_member = true
    case @project_team.team_members.include?(current_user)
      when true
        @team_membership = @project_team.team_memberships.where(team_member_id: current_user.id).first
        @project_team.team_memberships.destroy(@team_membership) unless @team_membership.nil?
        @add_member = false
      else
        new_member = TeamMembership.create(team_member_id: current_user.id, team_id: @project_team.id)
        new_member.save
        @add_member = true
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

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
