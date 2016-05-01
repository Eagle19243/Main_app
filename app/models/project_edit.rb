class ProjectEdit < ActiveRecord::Base
  include AASM

  belongs_to :user
  belongs_to :project

  aasm do
    state :pending, :initial => true
    state :accepted

    event :accept do
      transitions :from => :pending, :to => :accepted
    end
  end
end
