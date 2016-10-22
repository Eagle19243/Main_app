class CreateGroupmessages < ActiveRecord::Migration
  def change
    create_table :groupmessages do |t|
      t.text :messgae
      t.integer :groupmember_id, index: true, foreign_key: true

      t.integer :project_id, index: true, foreign_key: true
      t.integer :chatroom_id, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
