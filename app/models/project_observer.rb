class ProjectObserver < ActiveRecord::Observer

  def after_create(project)
    NotificationsService.notify_about_project_creation(project)
  end

end