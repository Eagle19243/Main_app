class AddSentAtToChangeLeaderInvitations < ActiveRecord::Migration
  def change
    add_column :change_leader_invitations, :sent_at, :timestamp
  end
end
