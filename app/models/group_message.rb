class GroupMessage < ActiveRecord::Base

  belongs_to :user
  belongs_to :chatroom
  has_many :user_message_read_flags, dependent: :destroy

  mount_uploader :attachment, AttachmentUploader # Tells rails to use this uploader for this model.

  def create_user_message_read_flags_for_all_groupmembers_except(user)
    self.chatroom.users.where.not(id: user.id).each do |chatroom_user|
      self.user_message_read_flags.create(read_status: false, user: chatroom_user)
    end
  end

end
