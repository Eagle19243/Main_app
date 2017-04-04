class Task < ActiveRecord::Base
  acts_as_paranoid

  include AASM
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
  has_many :donations, dependent: :delete_all
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

    event :accept do
      transitions :from => [:pending, :suggested_task], :to => :accepted
    end

    event :reject do
      transitions :from => [:pending, :accepted, :suggested_task], :to => :rejected
    end

    event :start_doing do
      transitions :from => [:accepted, :pending], :to => :doing
    end

    event :begin_review do
      transitions :from => [:doing], :to => :reviewing
    end

    event :complete do
      transitions :from => [:reviewing], :to => :completed
    end
  end

  validates :deadline, presence: true

  # TODO In future it would be a good idea to extract this into the Search object
  def self.fulltext_search(free_text, limit=10)
    # TODO Rails 5 has a OR method
    tasks = Task.where("title ILIKE ? OR description ILIKE ? OR short_description ILIKE ? OR condition_of_execution ILIKE ?", "%#{free_text}%", "%#{free_text}%", "%#{free_text}%","%#{free_text}%")
    tasks.limit(limit)
  end

  def not_fully_funded_or_less_teammembers?
    current_fund < budget ||  number_of_participants < target_number_of_participants
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
    we_serve_part = satoshi_budget * Payments::BTC::Base.weserve_fee

    (satoshi_budget - we_serve_part) / target_number_of_participants
  end

  def update_current_fund!
    self.current_fund = wallet.balance if wallet
    save!
  end

  def budget
    Payments::BTC::Converter.convert_satoshi_to_btc(self.satoshi_budget)
  end

  def budget=(satoshi_budget)
    self.satoshi_budget =  Payments::BTC::Converter.convert_btc_to_satoshi(satoshi_budget)
  end

  def funded
    budget == 0 ? "100%" : ((( Payments::BTC::Converter.convert_satoshi_to_btc(current_fund)  rescue 0) / budget) * 100).round.to_s + "%"
  end

  def any_fundings?
    self.current_fund != 0
  end

  def current_fund_of_task
    (Payments::BTC::Converter.convert_satoshi_to_btc(current_fund) rescue 0).round.to_s
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
