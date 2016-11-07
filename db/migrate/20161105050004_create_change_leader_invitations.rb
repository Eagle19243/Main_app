class CreateChangeLeaderInvitations < ActiveRecord::Migration
  def change
    create_table :change_leader_invitations do |t|

      t.string :former_leader
      t.string :new_leader
      t.timestamps null: false
    end
  end
end
