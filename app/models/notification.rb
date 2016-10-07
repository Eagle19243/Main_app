class Notification < ActiveRecord::Base
  enum type: [:basic, :become_project_admin_invitation]

  belongs_to :user
end
