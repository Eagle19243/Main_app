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

  def accept_task(user, task)
    @user = user
    @task = task
    mail(to: user.email, subject: ENV['accept_subject'])
  end
  
  def suggest_task(user, task)
    @user = user
    @task = task
    mail(to: user.email, subject: ENV['suggest_subject'])
  end

  def revision_approved(approver:, project:, receiver:)
    @approver = approver
    @project = project

    mail(to: receiver.email, subject: I18n.t('mailers.notification.revision_approved.subject'))
  end
end
