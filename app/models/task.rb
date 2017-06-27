class Task < ActiveRecord::Base
  include AASM
  include Searchable

  acts_as_paranoid

  default_scope -> { order('created_at DESC') }
  mount_uploader :fileone, PictureUploader
  mount_uploader :filetwo, PictureUploader
  mount_uploader :filethree, PictureUploader
  mount_uploader :filefour, PictureUploader
  mount_uploader :filefive, PictureUploader

  belongs_to :project
  belongs_to :user
  has_many :task_comments, dependent: :delete_all
  has_many :assignments, dependent: :delete_all
  has_many :do_requests, dependent: :delete_all
  has_many :task_attachments, dependent: :delete_all
  has_many :team_memberships, through: :task_members, dependent: :destroy
  has_many :task_members
  has_many :stripe_payments
  has_one :wallet, as: :wallet_owner

  MINIMUM_FUND_BUDGET = 1_200_000   # satoshis
  MINIMUM_DONATION_SIZE = 1_200_000 # satoshis

  aasm :column => 'state', :whiny_transitions => false do
    state :pending
    state :suggested_task
    state :accepted
    state :rejected
    state :doing
    state :reviewing
    state :completed
    state :incompleted

    event :accept do
      transitions :from => [:pending, :suggested_task], :to => :accepted
    end

    event :reject do
      transitions :from => [:pending, :accepted, :suggested_task], :to => :rejected
    end

    event :start_doing do
      transitions :from => [:accepted, :pending, :incompleted], :to => :doing
    end

    event :begin_review do
      transitions :from => [:doing], :to => :reviewing
    end

    event :incomplete do
      transitions :from => [:doing, :reviewing], :to => :incompleted
    end

    event :complete do
      transitions :from => [:reviewing], :to => :completed
    end
  end

  validates :title, presence: true
  validates :condition_of_execution, presence: true
  validates :proof_of_execution, presence: true
  validates :satoshi_budget, presence: true, unless: :free?
  validates :budget, numericality: { greater_than_or_equal_to: Payments::BTC::Converter.convert_satoshi_to_btc(MINIMUM_FUND_BUDGET) }, unless: :free?
  validates :deadline, presence: true
  validates :number_of_participants, numericality: { only_integer: true, less_than_or_equal_to: 1 }
  validates :target_number_of_participants, presence: true, numericality: { only_integer: true, equal_to: 1 }

  def self.fulltext_search(free_text, limit = 10)
    common_fulltext_search(
      %i(title description short_description condition_of_execution), free_text,
      limit
    )
  end

  def not_fully_funded_or_less_teammembers?
    !fully_funded? || !enough_teammembers?
  end

  def enough_teammembers?
    number_of_participants >= target_number_of_participants
  end

  def fully_funded?
    free? || current_fund >= budget
  end

  # Returns an estimation in Satoshi how many each participant is going to recieve
  #
  # Method calculates estimation using planned +satoshi_budget+ and planned
  # +target_number_of_participants+
  #
  # Returned value can't be used to calculate real transfer amounts because
  # real +current_fund+ and `team_memberships.size` need to be used to precise
  # calculations
  def planned_amount_per_member
    return 0 if free?
    we_serve_part = satoshi_budget * Payments::BTC::Base.weserve_fee

    (satoshi_budget - we_serve_part) / target_number_of_participants
  end

  def activities
    # We can do one query, but I think it will be harder to understand
    task_activities = Activity.where(targetable_id: self.id, targetable_type: 'Task')
    task_comments_activities = Activity.where(targetable_id: task_comments.ids, targetable_type: 'TaskComment')
    remove_task_assignee_activities = Activity.where(targetable_id: team_memberships.only_deleted.ids, targetable_type: 'TeamMembership')

    Activity.where(id: (task_activities.ids + task_comments_activities.ids + remove_task_assignee_activities.ids))
  end

  def current_fund
    wallet ? wallet.balance : 0.0
  end

  def update_current_fund!
    return false unless wallet
    wallet.update_balance!
  end

  def budget
    return 0 if free?
    Payments::BTC::Converter.convert_satoshi_to_btc(self.satoshi_budget)
  end

  def budget=(satoshi_budget)
    self.satoshi_budget =  Payments::BTC::Converter.convert_btc_to_satoshi(satoshi_budget)
  end

  def funded
    (budget == 0 || free?) ? "100%" : ((( Payments::BTC::Converter.convert_satoshi_to_btc(current_fund)  rescue 0) / budget) * 100).round.to_s + "%"
  end

  def funds_needed_to_fulfill_budget
    return 0 if completed?
    return 0 if free?

    delta = current_fund - satoshi_budget
    delta > 0 ? 0 : delta.abs
  end

  def any_fundings?
    current_fund > 0
  end

  def current_fund_of_task
    Payments::BTC::Converter.convert_satoshi_to_btc(current_fund).round.to_s
  end

  def team_relations_string
    number_of_participants.to_s + "/" + target_number_of_participants.to_s
  end

  def is_leader(user_id)
    users = team_memberships.where(role: 1).collect(&:team_member_id)
    (users.include? user_id) ? true : false
  end

  def is_executer(user_id)
    users = self.project.team.team_memberships.where(role: 3 ).collect(&:team_member_id)
    (users.include? user_id) ? true : false
  end

  def is_team_member( user_id )
    users = self.project.team.team_memberships.collect(&:team_member_id)
    (users.include? user_id) ? true : false
  end
end
