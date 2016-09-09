class RemoveSectionColumns < ActiveRecord::Migration
  def change
    reversible do |dir|
      Project.all.each do |p|
        dir.up do
            p.section_details.create(title:'First Section Details', context: p.section1)
            p.section_details.create(title:'Second Section Details', context: p.section2)
        end
        dir.down do
          p.update_attributes(section1: p.section_details.first.try(:context), section2: p.section_details.last.try(:context))
        end
      end
      revert do
        add_column :projects, :section1, :text
        add_column :projects, :section2, :text
      end
    end
  end
end
