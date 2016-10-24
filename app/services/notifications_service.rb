class NotificationsService

  def self.notify_about_admin_permissions(team_membership)
    self.create_notification(team_membership.team.project, team_membership.team_member, Notification.actions[:become_admin])
  end

  def self.notify_about_lost_admin_permissions(team_membership)
    self.create_notification(team_membership.team.project, team_membership.team_member, Notification.actions[:lost_project_admin_status])
  end

  def self.notify_about_admin_request(project, origin_user)
    self.create_notification(project, project.user, Notification.actions[:admin_request], origin_user)
  end

  def self.notify_about_project_creation(project)
    self.create_notification(project, project.user, Notification.actions[:created_project])
  end

  def self.notify_about_admin_invitation(project_id, user_id)
    self.create_notification(project_id, user_id, Notification.actions[:become_project_admin_invitation])
    #self.create_notification_by_ids(project_id, Project.name, user_id, Notification.actions[:become_project_admin_invitation])
  end

  def self.notify_about_applied_as_project_admin(project, origin_user)
    self.create_notification(project, project.user, Notification.actions[:applied_as_project_admin], origin_user)
  end

  private

  def self.create_notification(model, user, action, origin_user = nil)
    Notification.create(
        user: user,
        source_model: model,
        origin_user: origin_user,
        action: action
    )
  end

  def self.create_notification_by_ids(model_id, model_type, user_id, action)
    Notification.create(
        user_id: user_id,
        source_model_id: model_id,
        source_model_type: model_type,
        action: action
    )
  end
end