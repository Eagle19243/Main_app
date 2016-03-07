class TaskComment < ActiveRecord::Base
	default_scope -> { order('created_at DESC') }
	belongs_to :task
	belongs_to :user
end
