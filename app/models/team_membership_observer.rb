class TeamMembershipObserver < ActiveRecord::Observer

  def after_create(team_membership)
    NotificationsService.notify_team_member_about_admin_permissions(team_membership) if team_membership.admin?
  end

  def after_update(team_membership)
    if (team_membership.role_changed? && team_membership.admin?)
      NotificationsService.notify_team_member_about_admin_permissions(team_membership)
    elsif (team_membership.role_changed? && team_membership.role_was == "admin")
      NotificationsService.notify_about_lost_admin_permissions(team_membership)
    end
  end

  def after_destroy(team_membership)
    if team_membership.admin?
      NotificationsService.notify_about_lost_admin_permissions(team_membership)
    end
  end

end