class Notification < ActiveRecord::Base
  enum action: [:default, :become_admin]

  belongs_to :user
  belongs_to :origin_user, :foreign_key => 'origin_user_id', :class_name => 'User'
  belongs_to :source_model, polymorphic: true

  def create_notification(user, source_model, action, origin_user = nil)
    Notification.create(user: user, source_model: source_model, action: action, origin_user: origin_user)
  end
  
end
