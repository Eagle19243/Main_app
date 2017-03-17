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
  has_one :wallet_address
  has_many :task_comments, dependent: :delete_all
  has_many :assignments, dependent: :delete_all
  has_many :do_requests, dependent: :delete_all
  has_many :donations, dependent: :delete_all
  has_many :task_attachments, dependent: :delete_all
  has_many :team_memberships, through: :task_members, dependent: :destroy
  has_many :task_members
  has_many :stripe_payments

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

  #validates :proof_of_execution, presence: true
  #validates :title, presence: true, length: { minimum: 2, maximum: 30 }
  #validates :condition_of_execution, presence: true
  #validates :short_description, presence: true, length: { minimum: 20, maximum: 100 }
  #validates :description, presence: true
  #validates_numericality_of :budget, :only_integer => false, :greater_than_or_equal_to => 1
  #validates :budget, presence: true
  #validates :target_number_of_participants, presence: true
  #validates_numericality_of :target_number_of_participants, :only_integer => true, :greater_than_or_equal_to => 1

  # TODO In future it would be a good idea to extract this into the Search object
  def self.fulltext_search(free_text, limit=10)
    # TODO Rails 5 has a OR method
    tasks = Task.where("title ILIKE ? OR description ILIKE ? OR short_description ILIKE ? OR condition_of_execution ILIKE ?", "%#{free_text}%", "%#{free_text}%", "%#{free_text}%","%#{free_text}%")
    tasks.limit(limit)
  end

  def transfer_to_user_wallet(wallet_address_to_send_btc, amount)
    transfering_task = self
    @transfer = WalletTransaction.new(amount: amount, user_wallet: wallet_address_to_send_btc, task_id: self.id)
    satoshi_amount = amount if @transfer.valid?
    if (satoshi_amount.eql?('error') or satoshi_amount.blank?)
      @transfer.save
    else
      access_token = Payments::BTC::Base.bitgo_access_token
      address_from = transfering_task.wallet_address.wallet_id
      sender_wallet_pass_phrase = transfering_task.wallet_address.pass_phrase
      address_to = wallet_address_to_send_btc.strip
      @res = api.send_coins_to_address(wallet_id: address_from, address: address_to, amount: satoshi_amount, wallet_passphrase: sender_wallet_pass_phrase, access_token: access_token)
      unless @res["message"].blank?
        @transfer.save
      else
        @transfer.tx_hex = @res["tx"]
        @transfer.tx_id = @res["hash"]
        @transfer.task_id = transfering_task.id
        @transfer.save
      end
    end
  end

  def stripe_refund (funded_by_stripe, bitgo_fee)
    funded_by_stripe.each do |stripe_payment|
      total_bitgo_fee = ((stripe_payment.amount_in_satoshi * bitgo_fee) / 100)
      transfer_to_user = stripe_payment.amount_in_satoshi - total_bitgo_fee.to_i
      user_wallet = UserWalletAddress.where(user_id: stripe_payment.user_id).first
      transfer_to_user_wallet(user_wallet.sender_address,transfer_to_user)
    end
  end

  def user_wallet_refund(funds_from_user_wallets, bitgo_fee)
    funds_from_user_wallets.each do |wallet_transaction |
      total_bitgo_fee = (wallet_transaction.amount * bitgo_fee) / 100
      transfer_to_user = wallet_transaction.amount - total_bitgo_fee.to_i
      user_wallet = UserWalletAddress.where(user_id:  wallet_transaction.user_id).first
      transfer_to_user_wallet(user_wallet.sender_address,transfer_to_user)
    end
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
    transaction_fee = transfer_task_funds_transaction_fee
    amount_to_send = amount_after_bitgo_fee(satoshi_budget - transaction_fee)
    we_serve_part = amount_to_send * Payments::BTC::Base.weserve_fee

    (amount_to_send - we_serve_part) / target_number_of_participants
  end

  def transfer_task_funds
    update_current_fund!

    raise ArgumentError, "Task's budget is too low and cannot be transfered"   if satoshi_budget < MINIMUM_FUND_BUDGET
    raise ArgumentError, "Task fund level is too low and cannot be transfered" if current_fund < satoshi_budget

    transaction_fee = transfer_task_funds_transaction_fee
    amount_to_send = amount_after_bitgo_fee(current_fund - transaction_fee)
    we_serve_part = amount_to_send * Payments::BTC::Base.weserve_fee
    members_part = (amount_to_send - we_serve_part) / team_memberships.size

    recipients = build_recipients(team_memberships, members_part.to_i, we_serve_part.to_i)
    transfer_to_multiple_wallets(recipients, transaction_fee)
  end

  def transfer_task_funds_transaction_fee
    inputs = (current_fund / MINIMUM_DONATION_SIZE).to_i
    outputs = team_memberships.size + 2
    Payments::BTC::FeeCalculator.estimate(inputs, outputs)
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

  private
  def api
    Bitgo::V1::Api.new
  end

  def update_current_fund!
    response = api.get_wallet(
      wallet_id: wallet_address.wallet_id,
      access_token: Payments::BTC::Base.bitgo_access_token
    )
    update_attribute(:current_fund, response["balance"])
  end

  def transfer_to_multiple_wallets(recipients, fee)
    response = api.send_coins_to_multiple_addresses(
      wallet_id: wallet_address.wallet_id,
      wallet_passphrase: wallet_address.pass_phrase,
      recipients: recipients,
      fee: fee,
      access_token: Payments::BTC::Base.bitgo_access_token
    )

    if response["message"].blank?
      recipients.map do |recipient|
        WalletTransaction.create(
          tx_hex: response["tx"],
          tx_id: response["hash"],
          amount: recipient[:amount],
          user_wallet: recipient[:address],
          task_id: id
        )
      end
    else
      raise response.inspect
    end
  end

  def amount_after_bitgo_fee(amount)
    (amount - (amount * Payments::BTC::Base.bitgo_fee))
  end

  def build_recipients(memberships, per_member_amount, we_serve_amount)
    recipients = memberships.map do |membership|
      {
        address: membership.team_member.user_wallet_address.sender_address,
        amount: per_member_amount
      }
    end

    if we_serve_amount > 0
      recipients << {
        address: Payments::BTC::Base.weserve_wallet_address,
        amount: we_serve_amount
      }
    end

    recipients
  end
end
