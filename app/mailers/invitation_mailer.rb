class InvitationMailer < ApplicationMailer
  def invite_user(email,user_name,task_title )
    @task_title=task_title
    @user_name =user_name
    mail(to: email, subject: 'invitation For Task')
  end

end
