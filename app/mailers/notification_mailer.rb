class NotificationMailer < ApplicationMailer

  def invite_admin(email, user_name, project)
    @project = project
    @user_name = user_name
    mail(to: email, subject: t('.subject'))
  end

  def suggest_task(user, task)
    @user = user
    @task = task
    mail(to: user.email, subject: t('.subject'))
  end

  def accept_new_task(task:, receiver:)
    @receiver = receiver
    @task = task
    mail(to: @receiver.email, subject: t('.subject'))
  end

  def task_started(acting_user:, task:, receiver:)
    @acting_user = acting_user
    @task = task
    @receiver = receiver

    mail(to: receiver.email, subject: t('.subject'))
  end

  def under_review_task(reviewee:, task:, receiver:)
    @task = task
    @reviewee = reviewee
    @receiver = receiver

    mail(to: receiver.email, subject: t('.subject'))
  end

  def revision_approved(approver:, project:, receiver:)
    @approver = approver
    @project = project

    mail(to: receiver.email, subject: t('.subject'))
  end

  def notify_user_for_rejecting_new_task(task_title:, project:, receiver:)
    set_instance_variables_for_rejected_tasks(task_title: task_title, project: project, receiver: receiver)
    mail(to: @receiver.email, subject: t('.subject'))
  end

  def notify_others_for_rejecting_new_task(task_title:, project:, receiver:)
    set_instance_variables_for_rejected_tasks(task_title: task_title, project: project, receiver: receiver)
    mail(to: @receiver.email, subject: t('.subject'))
  end

  def comment(task_comment:, receiver:)
    @task_comment = task_comment
    @receiver = receiver

    mail(to: @receiver.email, subject: t('.subject'))
  end

  def task_deleted(task_title:, project:, receiver:, admin:)
    set_instance_variables_for_rejected_tasks(task_title: task_title, project: project, receiver: receiver)
    @admin = admin

    mail(to: @receiver.email, subject: t('.subject'))
  end

  def task_completed(task:, receiver:, reviewer:)
    @task = task
    @reviewer = reviewer
    @receiver = receiver

    mail(to: @receiver.email, subject: t('.subject'))
  end

  def task_incomplete(task:, receiver:, reviewer:)
    @task = task
    @reviewer = reviewer
    @receiver = receiver

    mail(to: receiver.email, subject: t('.subject'))
  end

  private

  def set_instance_variables_for_rejected_tasks(task_title:, project:, receiver:)
    @task_title = task_title
    @project = project
    @receiver = receiver
  end
end
