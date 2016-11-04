class Groupmessage < ActiveRecord::Base
  belongs_to :Groupmember
  belongs_to :Chatroom
  belongs_to :Project
end
