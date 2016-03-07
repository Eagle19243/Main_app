class ProjectComment < ActiveRecord::Base
	 default_scope -> { order('created_at DESC') }
	belongs_to :project
	belongs_to :user
end
