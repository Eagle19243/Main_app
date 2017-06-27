class Activity < ActiveRecord::Base
	belongs_to :user
	belongs_to :targetable, polymorphic: true

	def archived_targetable
		targetable_type.constantize.only_deleted.find_by(id: targetable_id)
	end

	%w(created edited deleted incomplete).each do |action_name|
		define_method("#{action_name}?") do
			action == action_name
		end
	end
end
