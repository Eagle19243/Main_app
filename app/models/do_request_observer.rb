class DoRequestObserver < ActiveRecord::Observer
  def after_save
    if (self.state == "pending")
      NotificationsService.notify_about_pending_do_request(self, self.task.project.user)
    end
  end
end