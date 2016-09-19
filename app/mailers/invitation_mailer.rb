class InvitationMailer < ApplicationMailer
  def invite_user(email,user_name,task )
    @task_title=task
    @user_name =user_name
    mail(to: email, subject: 'invitation For Task')
  end

end
