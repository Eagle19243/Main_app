class ProjectObserver < ActiveRecord::Observer
  def after_create
    NotificationsService.notify_about_project_creation(self)
  end
end