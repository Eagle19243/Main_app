class StripePayment < ActiveRecord::Base
  belongs_to :task
end
