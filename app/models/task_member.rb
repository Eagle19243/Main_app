class TaskMember < ActiveRecord::Base
  validates_uniqueness_of :task_id, :scope => :team_membership_id
end
