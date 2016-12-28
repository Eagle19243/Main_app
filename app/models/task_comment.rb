class TaskComment < ActiveRecord::Base
	mount_uploader :attachment, AttachmentUploader
	default_scope -> { order('created_at DESC') }
	belongs_to :task
	belongs_to :user
end
