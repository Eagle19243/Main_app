class TaskComment < ActiveRecord::Base
  default_scope -> { order('created_at DESC') }

  belongs_to :task
  belongs_to :user

  mount_uploader :attachment, AttachmentUploader

  validates :body, presence: true, unless: :attachment?
end
