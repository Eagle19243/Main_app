class TeamMembership < ActiveRecord::Base
  enum role: [:employee, :project_leader, :admin]

  belongs_to :team
  belongs_to :team_member, foreign_key: "team_member_id", class_name: "User"
  has_many :tasks, through: :task_members, dependent: :destroy

  def self.get_roles 
    humanize_roles = [] 
    roles.each do |key, value|
      if value != roles[:project_leader] 
        humanize_roles << [key, key.humanize] 
      end
    end
    humanize_roles
  end

end
