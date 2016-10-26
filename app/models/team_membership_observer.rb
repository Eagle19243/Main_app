class TeamMembershipObserver < ActiveRecord::Observer

  def after_save
    NotificationsService.notify_about_admin_permissions(self.team.project, self.team_member)
  end

  def after_update
    if (self.role_changed? && self.role == "admin")
      NotificationsService.notify_about_admin_permissions(self.team.project, self.team_member)
    elsif (self.role_changed? && self.role_was == "admin")
      NotificationsService.notify_about_lost_admin_permissions(self)
    end
  end
end