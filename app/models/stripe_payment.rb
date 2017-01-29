class StripePayment < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :task
  belongs_to :user
end
