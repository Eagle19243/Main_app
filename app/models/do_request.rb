class DoRequest < ActiveRecord::Base
	include AASM
    default_scope -> { order('created_at DESC') }
    belongs_to :task
    belongs_to :user
    validates_uniqueness_of :user_id, :scope => :task_id, :message =>"Your application cannot be processed"
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
