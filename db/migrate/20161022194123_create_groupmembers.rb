class CreateGroupmembers < ActiveRecord::Migration
  def change
    create_table :groupmembers do |t|
      t.integer :project_id, index: true, foreign_key: true
      t.integer :chatroom_id, index: true, foreign_key: true
      t.integer :user_id, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
