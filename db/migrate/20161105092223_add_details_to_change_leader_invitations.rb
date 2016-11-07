class AddDetailsToChangeLeaderInvitations < ActiveRecord::Migration
  def change
    add_column :change_leader_invitations, :accepted_at, :timestamp
    add_column :change_leader_invitations, :rejected_at, :timestamp
  end
end
