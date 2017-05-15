class InvitationMailer < ApplicationMailer
  def invite_user(email, user_name, task )
    @task = task
    @user_name = user_name
    mail(to: email, subject: t('.subject'))
  end

  def invite_user_for_project(email, user_name, project_id)
    @user_name = user_name
    @project = Project.find(project_id)
    mail(to: email, subject: t('.subject'))
  end

  def invite_leader(invitation_id)
    @invitation = ChangeLeaderInvitation.find invitation_id
    @from = @invitation.project.user.email
    @user_name = @invitation.project.user.display_name
    @url = project_url(@invitation.project)
    mail(to: @invitation.new_leader, subject: t('.subject'))
  end

  def notify_previous_leader_for_new_leader(project:, previous_leader:)
    @project = project
    @new_leader = project.user
    @previous_leader = previous_leader

    mail(to: @previous_leader.email, subject: t('.subject'))
  end

  def welcome_user(email_address)
    @user_name = User.find_by(email: email_address).display_name
    mail(to: email_address, subject: t('.subject'))
  end
end
