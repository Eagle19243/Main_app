class AdminInvitation < ActiveRecord::Base
  enum status: [:pending, :accepted, :rejected]

  belongs_to :user
  belongs_to :project
  belongs_to :sender, class_name: 'User', foreign_key: :sender_id

  validates :user, presence: true
  validates :sender, presence: true
  validates :project, presence: true
end
