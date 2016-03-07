class AddVolunteersToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :volunteers, :integers, default: 0
  end
end
