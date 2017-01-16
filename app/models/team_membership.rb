class TeamMembership < ActiveRecord::Base
  enum role: [ :volunteer, :leader,  :lead_editor, :executor]
  belongs_to :team
  belongs_to :team_member, foreign_key: "team_member_id", class_name: "User"
  has_many :tasks, through: :task_members, dependent: :destroy
  has_many :task_members

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
