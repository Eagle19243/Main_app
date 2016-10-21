class TeamMembershipObserver < ActiveRecord::Observer
  def after_update
    if (self.role_changed? && self.role == "admin")
      NotificationsService.notify_about_admin_permissions(self)
      NotificationsService.notify_about_lost_admin_permissions(self)
    end
    Notification.create(user: User.first, source_model: first)
  end
end