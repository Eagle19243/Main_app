class CreateSectionDetails < ActiveRecord::Migration
  def change
    create_table :section_details do |t|
      t.references :project, index: true, foreign_key: true
      t.integer :order
      t.string :title
      t.text :context, default: ''
      t.timestamps null: false
    end
  end
end
