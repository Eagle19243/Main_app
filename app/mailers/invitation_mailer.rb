class InvitationMailer < ApplicationMailer
  def invite_user(email,user_name,task )
    @task = task
    @user_name = user_name
    mail(to: email, subject: 'invitation For Task')
  end

  def invite_user_for_project(email,user_name,title,project_id)
    @title=title
    @user_name =user_name
    @orignal_url = 'http://weserve.io'
    @URL = project_id
    mail(to: email, subject: 'invitation For Project')
  end

  def invite_leader(invitation_id)
    @invitation = ChangeLeaderInvitation.find invitation_id
    @from = @invitation.project.user.email
    @user_name = @invitation.project.user.name
    @url = project_url(@invitation.project)
    mail(to: @invitation.new_leader, subject: "Invitation for Project")
  end

  def notify_previous_leader_for_new_leader(project:, previous_leader:)
    @project = project
    @new_leader = project.user
    @previous_leader = previous_leader

    mail(to: @previous_leader.email, subject: 'New leader accepted invitation')
  end

  def welcome_user(email_address)
    @user_name = User.find_by(email: email_address).name
    mail(to: email_address, subject: "Welcome to Weserve")
  end
end
