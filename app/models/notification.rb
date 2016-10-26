class Notification < ActiveRecord::Base
  enum action: [
      :default,
      :became_project_admin,
      :lost_project_admin_status,
      :created_project,
      :become_project_admin_invitation,
      :applied_as_project_admin,
      :reject_admin_invitation,
      :accept_admin_invitation,
      :suggested_task,
      :pending_do_request
  ]

  belongs_to :user
  belongs_to :origin_user, :foreign_key => 'origin_user_id', :class_name => 'User'
  belongs_to :source_model, polymorphic: true

  validates :user, presence: true
  validates :source_model, presence: true

end
