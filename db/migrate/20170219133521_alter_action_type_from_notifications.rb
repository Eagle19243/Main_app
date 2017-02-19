class AlterActionTypeFromNotifications < ActiveRecord::Migration
  def change
    change_column :notifications, :action_type, :string
  end
end
