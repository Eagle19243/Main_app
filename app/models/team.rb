class Team < ActiveRecord::Base
  belongs_to :project
  has_many :team_memberships
  has_many :team_members, :through => :team_memberships, class_name: "User", foreign_key: "team_id"
end
