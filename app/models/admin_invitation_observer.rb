class AdminInvitationObserver < ActiveRecord::Observer
  def after_create
    NotificationsService.notify_about_admin_invitation(self, current_user)
  end

  def after_update
    if self.status == "accepted"
      NotificationsService.notify_about_admin_permissions(self.project, self.user)
      NotificationsService.notify_about_admin_accept_invitation()
    else
      NotificationsService.notify_about_reject_admin_invitation()
    end
  end
end