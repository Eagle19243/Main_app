class TaskObserver < ActiveRecord::Observer
  def after_save
    if (self.state == 'suggested_task')
      NotificationsService.notify_about_suggested_task(self, self.project.user)
    end
  end
end