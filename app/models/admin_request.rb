class AdminRequest < ActiveRecord::Base
  enum status: [:pending, :accepted, :rejected]

  belongs_to :project
  belongs_to :sender, class_name: 'User', foreign_key: :user_id

  validates :sender, presence: true
  validates :project, presence: true
end
