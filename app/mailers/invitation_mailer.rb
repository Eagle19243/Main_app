class InvitationMailer < ApplicationMailer
  def invite_user(email,user_name,task )
    @task=task
    @user_name =user_name
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
    mail(to: email, subject: "Invitation for Project")
  end
end
