class ChangeLeaderInvitationController < ApplicationController
  def accept
    @invitation = ChangeLeaderInvitation.find params[:id]
    @invitation.accept!
    project = @invitation.project
    project.user_id = current_user.id
    if project.valid?
      project.save!
      flash[:notice] = "Congratulations! You are project leader of " + @invitation.project.title + "!"
      project.project_users.each do |user_id|
        user = User.find user_id.user_id
        NotificationsService.notify_about_leader_change(user, current_user, project)
      end
    else
      flash[:alert] = project.errors.messages.to_s
    end
    redirect_to :my_projects
  end

  def reject
    @invitation = ChangeLeaderInvitation.find params[:id]
    @invitation.reject!
  end
end