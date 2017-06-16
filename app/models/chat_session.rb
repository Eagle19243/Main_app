class ChatSession < ActiveRecord::Base
  belongs_to :requester, class_name: 'User'
  belongs_to :receiver, class_name: 'User'

  validates_presence_of :requester, :receiver

  before_create :session_state

  def session_state(force)
    self.uuid = SecureRandom.uuid if uuid.nil? || force
    self.status = 'pending'
  end
end
