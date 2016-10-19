class NotificationsService

  def self.send_become_admin_notification(team_membership)
    Notification.create(user: team_membership.team_member,
                        source_model: team_membership,
                        action: Notification.actions[:become_admin])
  end
end