class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :title
      t.text :description
      t.string :country
      t.string :picture

      t.timestamps null: false
    end
  end
end
