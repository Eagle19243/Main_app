class Task < ActiveRecord::Base
  acts_as_paranoid

  include ApplicationHelper
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

  # after create, assign a Bitcoin address to the task, toggle the comment below to enable
  after_create :assign_address
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
      transitions :from => [:pending, :suggested_task], :to => :rejected
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

  searchable do
    text :title
    text :description
    text :short_description
    text :condition_of_execution
  end

  def assign_address
    if_address_available = GenerateAddress.where(is_available: true)
    unless if_address_available.blank?
      begin
       wallet = if_address_available.first
       WalletAddress.create(sender_address: wallet.sender_address, receiver_address: wallet.receiver_address, pass_phrase: wallet.pass_phrase, task_id: self.id, wallet_id: wallet.wallet_id)
        update_address_availability = wallet
        update_address_availability.update_attribute('is_available', 'false')
      rescue => e
        puts e.message unless Rails.env == "development"
      end
    else
      access_token = access_wallet
      #Rails.logger.info access_token unless Rails.env == "development"
      api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
      secure_passphrase = SecureRandom.hex(5)
      secure_label = SecureRandom.hex(5)
      new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)
      #Rails.logger.info "Wallet Passphrase #{secure_passphrase}" unless Rails.env == "development"
      new_address_id = new_address["wallet"]["id"] rescue "assigning new address ID"
     # puts "New Wallet Id #{new_address_id}" unless Rails.env == "development"
      new_wallet_address_sender = api.create_address(wallet_id: new_address_id, chain: "0", access_token: access_token) rescue "create address"
      new_wallet_address_receiver = api.create_address(wallet_id: new_address_id, chain: "1", access_token: access_token) rescue "address receiver"
    #  Rails.logger.info new_wallet_address_sender.inspect unless Rails.env == "development"
     # Rails.logger.info new_wallet_address_receiver.inspect unless Rails.env == "development"
      #Rails.logger.info "#Address #{new_wallet_address_sender["address"]}" rescue 'Address not Created'
      #Rails.logger.info "#Address #{new_wallet_address_receiver["address"]}" rescue 'Address not Created'
      unless new_address.blank?
        WalletAddress.create(sender_address: new_wallet_address_sender["address"], receiver_address: new_wallet_address_receiver["address"], pass_phrase: secure_passphrase, task_id: self.id, wallet_id: new_address_id)
      else
        WalletAddress.create(sender_address: nil, task_id: self.id)
      end
    end
  end

  def transfer_to_user_wallet(wallet_address_to_send_btc, amount)
    transfering_task = self
    begin
      @transfer = WalletTransaction.new(amount: amount, user_wallet: wallet_address_to_send_btc, task_id: self.id)
      satoshi_amount = nil
      satoshi_amount = convert_usd_to_btc_and_then_satoshi(params['amount']) if @transfer.valid?
      if (satoshi_amount.eql?('error') or satoshi_amount.blank?)
        @transfer.save
      else
        access_token = access_wallet
        address_from = transfering_task.wallet_address.wallet_id
        sender_wallet_pass_phrase = transfering_task.wallet_address.pass_phrase
        address_to = wallet_address_to_send_btc.strip
        api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
        @res = api.send_coins_to_address(wallet_id: address_from, address: address_to, amount: satoshi_amount, wallet_passphrase: sender_wallet_pass_phrase, access_token: access_token)
        unless @res["message"].blank?
          @transfer.save
        else
          @transfer.tx_hash = @res["tx"]
          @transfer.task_id = transfering_task.id
          @transfer.save
        end
      end
    rescue => e
      @transfer.save
    end
  end


  def transfer_task_funds
    bitgo_fee = 0.10
    we_serve_wallet = '385dMgNnjxCK5PU84gNSYeRWD668gaG9PL'
    wallet_address = self.wallet_address
    total_budget = self.budget
    #users = self.team_memberships

    team_members = self.team_memberships
    #team_members = TeamMembership.where(task_id: self.id)
    if (team_members.blank?)
      transfer_to_user_wallet(we_serve_wallet, total_budget)
    else
      num_of_participants = team_members.count
      total_bitgo_fee = ((total_budget * bitgo_fee) / 100) * (num_of_participants + 1)
      total_after_bitgo_fee = total_budget - total_bitgo_fee
      we_serve_fee = (total_after_bitgo_fee * 5)/100
      total_after_we_serve_fee = total_after_bitgo_fee - we_serve_fee
      each_team_member_fee = total_after_we_serve_fee / num_of_participants
      transfer_to_user_wallet(we_serve_wallet, we_serve_fee)
      team_members.each do |member|
        transfer_to_user_wallet(member.team_member.user_wallet_address.sender_address, each_team_member_fee)
      end
    end

  end

  def funded
    budget == 0 ? "100%" : (((current_fund + (curent_bts_to_usd (id) rescue 0)) / budget) * 100).round.to_s + " %"
  end

  def funded_in_btc
    ((self.wallet_address.current_balance.to_s rescue '0') + ' ฿')
  end

  def current_fund_of_task
    (current_fund+(curent_bts_to_usd(id) rescue 0)).round.to_s
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
