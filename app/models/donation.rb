class Donation < ActiveRecord::Base
  require "pp-adaptive"
	belongs_to :user
	belongs_to :task

  validates_numericality_of :amount, :only_integer => true, :greater_than_or_equal_to => 1
end
