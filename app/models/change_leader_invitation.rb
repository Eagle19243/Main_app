# project_id
# email
# sent_at
# accepted_at
# rejected_at
# created_at
# updated_at

class ChangeLeaderInvitation < ActiveRecord::Base
  belongs_to :project

  scope :pending, -> { where("accepted_at IS NULL or rejected_at IS NULL") }

  def accept!
    self.update(accepted_at: Time.current, status: false)
  end

  def reject!
    self.update(rejected_at: Time.current, status: false)
  end
end