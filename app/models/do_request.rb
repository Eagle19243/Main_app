class DoRequest < ActiveRecord::Base
	include AASM
    default_scope -> { order('created_at DESC') }
    belongs_to :task
    belongs_to :user
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
