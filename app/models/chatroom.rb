class Chatroom < ActiveRecord::Base
  belongs_to :Project
  belongs_to :user
end
