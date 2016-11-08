class GroupMessage < ActiveRecord::Base
  belongs_to :user
  belongs_to :chatroom
  mount_uploader :attachment, AttachmentUploader # Tells rails to use this uploader for this model.
end
