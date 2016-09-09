class TaskAttachment < ActiveRecord::Base
  mount_uploader :attachment, AttachmentUploader # Tells rails to use this uploader for this model.
  validates :task_id, presence: true
  validates :attachment, presence: true
  belongs_to :task
end
