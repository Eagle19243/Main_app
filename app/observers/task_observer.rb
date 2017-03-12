class TaskObserver < ActiveRecord::Observer
  def after_create(task)
    if (task.suggested_task?)
      NotificationsService.notify_about_suggested_task(task)
    end
  end
end
