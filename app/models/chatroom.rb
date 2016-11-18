class Chatroom < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  belongs_to :friend, foreign_key: "friend_id", class_name: "User"
  has_many :groupmembers, dependent: :destroy
end
