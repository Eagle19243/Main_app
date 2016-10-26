class TeamMembershipObserver < ActiveRecord::Observer
  def after_update
    if (self.role_changed? && self.role == "admin")
      NotificationsService.notify_about_admin_permissions(self.team.project, self.team_member)
      NotificationsService.notify_about_lost_admin_permissions(self)
    elsif (self.role_changed? && self.role_was == "admin")
      NotificationsService.notify_about_lost_admin_permissions(self)
    end
  end
end