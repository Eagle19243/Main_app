class TeamMembership < ActiveRecord::Base
  enum role: [ :teammate, :leader,  :lead_editor, :coordinator]

  belongs_to :team
  belongs_to :team_member, foreign_key: "team_member_id", class_name: "User"
  has_many :tasks, through: :task_members, dependent: :destroy
  has_many :task_members

  COORDINATOR_ID = roles["coordinator"].freeze
  LEAD_EDITOR_ID = roles["lead_editor"].freeze
  TEAM_MATE_ID   = roles["teammate"].freeze

  def self.get_roles
    humanize_roles = []
    roles.each do |key, value|
      if value != roles[:leader]
        humanize_roles << [key, key.humanize]
      end
    end
    humanize_roles
  end

end
