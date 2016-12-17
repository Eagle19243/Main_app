class ApplyRequest < ActiveRecord::Base
  enum request_type: [:Lead_Editor, :Executor]  
  belongs_to :user
  belongs_to :project
  validates :user, presence: true
  validates :project, presence: true

  scope :pending, -> { where("accepted_at IS NULL and rejected_at IS NULL") }
  def user_name 
    User.find(self.user_id).name
  end

  def is_valid?
    accepted_at.nil? && rejected_at.nil?
  end

  def accept!
    self.update(accepted_at: Time.current)
  end

  def reject!
    self.update(rejected_at: Time.current)
  end
end
