class AddStatusToChangeLeaderInvitations < ActiveRecord::Migration
  def change
    add_column :change_leader_invitations, :status, :boolean 
  end
end
