class Assignment < ActiveRecord::Base
	include AASM
	belongs_to :user
	belongs_to :task
	validates_uniqueness_of :user_id, :scope => :task_id


	 aasm :column => 'state', :whiny_transitions => false do
    state :pending
    state :accepted
    state :rejected
    event :accept do
      transitions :from => :pending, :to => :accepted
    end
    event :reject do
      transitions :from => :pending, :to => :rejected

    end  
    end  
end
