class InstitutionUser < ActiveRecord::Base
  belongs_to :institution
  belongs_to :user
end
