class AdminInvitationObserver < ActiveRecord::Observer
  def after_create
    NotificationsService.notify_about_admin_invitation(self, current_user)
  end

  def after_update
    if self.status_changed?
      if self.status == "accepted"
        NotificationsService.notify_about_admin_permissions(self.project, self.user)
        NotificationsService.notify_about_accept_admin_invitation(self, self.project.user, self.user)
      elsif self.status == "rejected"
        NotificationsService.notify_about_reject_admin_invitation(self, self.project.user, self.user)
      end
    end
  end
end