class SectionDetail < ActiveRecord::Base
  include Discussable

  belongs_to :project

  belongs_to :parent, class_name: 'SectionDetail', foreign_key: 'parent_id'

  has_many :childs, class_name: 'SectionDetail', foreign_key: 'parent_id', dependent: :nullify

  scope :of_parent, ->(p){ p ? p.childs : where(parent_id: nil)}

  scope :ordered, ->{order(:order,:title)}

  scope :completed, ->{where.not(context: '')}

  attr_accessor :discussed_context

  validates :title, presence: true

  def can_update?
    User.current_user.is_admin_for?(self.project)
  end

  def discussed_context= value
    if can_update?
      self.send(:write_attribute, 'context', value)
    else
      unless value == self.context.to_s
        Discussion.find_or_initialize_by(discussable:self, user_id: User.current_user.id, field_name: 'context').update_attributes(context: value)
      end
    end
  end

  def discussed_context
    can_update? ?
        self.send(:context) :
        discussions.of_field('context').of_user(User.current_user).last.try(:context) || self.send(:read_attribute, 'context')
  end

end