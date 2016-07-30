class Institution < ActiveRecord::Base
	has_many :projects
	# an institution can have many institutions, the join table for this has been named :institution_users
  has_many :institution_users
  has_many :users, :through => :institution_users
end
