class TeamService

  def self.add_admin_to_project(project, user)
    self.add_team_member(project.team, user, TeamMembership.roles[:admin])
  end

  private

  def self.add_team_member(team, member, role)
    tt = TeamMembership.where("team_id = ? AND team_member_id = ?", team.id, member.id).first
    if tt.nil?
      TeamMembership.create(
        team_member: member,
        team: team,
        role: role
      )
    else
      tt.update(role: role)
    end
  end
end
