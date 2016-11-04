class TeamService

  def self.add_admin_to_project(project, user)
    self.add_team_member(project.team, user, TeamMembership.roles[:admin])
  end

  private

  def self.add_team_member(team, member, role)
    TeamMembership.create(
        team_member: member,
        team: team,
        role: role
    )
  end

end