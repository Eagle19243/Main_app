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
    self.create_notification(project, User.where(role == User.roles[:admin]).first, Notification.actions[:user_created_project], project.user)
  end

  def self.notify_about_admin_invitation(project, user)
    self.create_notification(project, user, Notification.actions[:become_project_admin_invitation])
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

end