class MailPreview < MailView

  def task_share_email
    email = 'new_user@test.com'
    user_name = 'inviting_user'
    task = Task.first
    InvitationMailer.invite_user(email,user_name,task )
  end

  def project_share_email
    email = 'new_user@test.com'
    user_name = 'inviting_user'
    project_id = Project.first.id

    InvitationMailer.invite_user_for_project(email,user_name,project_id)
  end

end
