class ChangeNotificationsColumns < ActiveRecord::Migration
  def change
    add_column :notifications, :view_params, :text
    add_reference :notifications, :user, foreign_key: true
    change_column :notifications, :type, :integer, default: 0
  end
end
