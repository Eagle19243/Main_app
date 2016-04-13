class Assignment < ActiveRecord::Base
	include AASM
	belongs_to :user
	belongs_to :task
	validates_uniqueness_of :user_id, :scope => :task_id


	 aasm :column => 'state', :whiny_transitions => false do
    state :pending
    state :accepted
    state :rejected
    state :completed
    state :confirmed
    state :unconfirmed
    event :accept do
      transitions :from => :pending, :to => :accepted
    end
    event :reject do
      transitions :from => :pending, :to => :rejected

    end  
    event :complete do
        transitions :from =>[:accepted, :unconfirmed], :to =>:completed

    end

   event :verify do
        transitions :from =>[:completed], :to =>:confirmed
   end 

   event :unconfirm do   
    transitions :from =>:completed, :to =>:unconfirmed

   end 


    end  
end
