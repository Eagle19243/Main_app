class ProjectComment < ActiveRecord::Base
  acts_as_paranoid
  default_scope -> { order('created_at DESC') }
  belongs_to :project
  belongs_to :user

  validates :user_id, presence: true
  validates :project_id, presence: true
end
