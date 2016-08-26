class FavoriteProject < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  validates_uniqueness_of :project_id, :scope => [:user_id]
end
