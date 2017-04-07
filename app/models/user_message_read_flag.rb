class UserMessageReadFlag< ActiveRecord::Base

  belongs_to :user
  belongs_to :group_message

  scope :unread, -> { where(read_status: false) }

  def mark_as_read
    self.update_attribute(:read_status,true)
  end
  
end
