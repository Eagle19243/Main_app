class Groupmember < ActiveRecord::Base
  belongs_to :Project
  belongs_to :Chatroom
end
