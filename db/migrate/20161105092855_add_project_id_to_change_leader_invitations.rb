class AddProjectIdToChangeLeaderInvitations < ActiveRecord::Migration
  def change
    add_column :change_leader_invitations, :project_id, :string
    remove_column :change_leader_invitations, :created_at, :timestamp
    remove_column :change_leader_invitations, :updated_at, :timestamp
  end
end
