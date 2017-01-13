class Notification < ActiveRecord::Base
  enum action: [
      :default,
      :became_project_admin,
      :lost_project_admin_status,
      :created_project,
      :updated_project,
      :become_project_admin_invitation,
      :admin_request,
      :reject_admin_invitation,
      :accept_admin_invitation,
      :reject_admin_request,
      :accept_admin_request,
      :suggested_task,
      :pending_do_request,
      :leader_change,
      :apply_requset,
      :accept_apply_request,
      :reject_apply_request
  ]

  belongs_to :user
  belongs_to :origin_user, :foreign_key => 'origin_user_id', :class_name => 'User'
  belongs_to :source_model, polymorphic: true

  validates :user, presence: true
  validates :source_model, presence: true

  def self.unread
    where(:read => false)
  end

end
