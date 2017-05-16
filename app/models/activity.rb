class Activity < ActiveRecord::Base
	belongs_to :user
	belongs_to :targetable, polymorphic: true

	def archived_targetable
		targetable_type.constantize.only_deleted.find_by(id: targetable_id) if targetable_type.constantize.method_defined?(:only_deleted)
	end
end
