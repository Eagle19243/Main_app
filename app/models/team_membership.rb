class TeamMembership < ActiveRecord::Base
  belongs_to :team
  belongs_to :team_member, foreign_key: "team_member_id", class_name: "User"
end
