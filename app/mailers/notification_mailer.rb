class NotificationMailer < ApplicationMailer

  def invite_admin(email,user_name, project)
    @project = project
    @user_name = user_name
    mail(to: email, subject: 'invitation For Project')
  end
  
  def suggest_task(user, task)
    @user = user
    @task = task
    mail(to: user.email, subject: ENV['suggest_subject'])
  end
end
