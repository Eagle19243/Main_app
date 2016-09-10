class ProfileComment < ActiveRecord::Base
  paginates_per 5

  belongs_to :commenter, class_name: "User"
  belongs_to :receiver, class_name: "User"
  validates :commenter_id, presence: true
  validates :receiver_id, presence: true
end
