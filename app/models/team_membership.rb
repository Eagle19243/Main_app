class TeamMembership < ActiveRecord::Base
  enum role: [:employee, :project_leader, :admin]

  belongs_to :team
  belongs_to :team_member, foreign_key: "team_member_id", class_name: "User"
end
