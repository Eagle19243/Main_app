class Discussion < ActiveRecord::Base
  belongs_to :discussable, polymorphic: true
  belongs_to :user

  validates :context, :field_name, :user_id, presence: true

  scope :of_field, ->(f){ where field_name: f if f }
  scope :of_user, ->(u){ where user_id: u.id if u }

  def accept_context
    discussable.send(:write_attribute, field_name, self.context)
    destroy if discussable.save
  end
end