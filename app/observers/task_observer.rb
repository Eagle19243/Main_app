class TaskObserver < ActiveRecord::Observer
  def after_create(task)
    if (task.suggested_task?)
      NotificationsService.notify_about_suggested_task(task)
      
      NotificationMailer.suggest_task(task.project.user, task).deliver_now
      task.project.followers.each do |user|
        NotificationMailer.suggest_task(user, task).deliver_now
      end
    end
  end
end
