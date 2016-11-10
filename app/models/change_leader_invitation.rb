# project_id
# email
# sent_at
# accepted_at
# rejected_at
# created_at
# updated_at

class ChangeLeaderInvitation < ActiveRecord::Base
  belongs_to :project

  scope :pending, -> { where("accepted_at IS NULL and rejected_at IS NULL") }

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
