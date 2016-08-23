class Task < ActiveRecord::Base
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

	# after create, assign a Bitcoin address to the task, toggle the comment below to enable
  #after_create :assign_address
	aasm :column => 'state', :whiny_transitions => false do
    state :pending
    state :accepted
    state :rejected
		state :doing
		state :reviewing
		state :completed

		event :accept do
      transitions :from => :pending, :to => :accepted
    end
		event :reject do
      transitions :from => :pending, :to => :rejected
    end
		event :start_doing do
			transitions :from => [:accepted, :pending, :reviewing, :completed], :to => :doing
		end
		event :begin_review do
			transitions :from => [:accepted, :pending, :completed, :doing], :to => :reviewing
		end
		event :complete do
      transitions :from => [:accepted, :pending, :doing, :reviewing], :to => :completed
    end

  end

  validates :proof_of_execution, presence: true
  validates :title, presence: true, length: { minimum: 2, maximum: 30 }
  validates :condition_of_execution, presence: true
  validates :short_description, presence: true, length: { minimum: 20, maximum: 100 }
  validates :description, presence: true
  validates_numericality_of :budget, :only_integer => false, :greater_than_or_equal_to => 1
  validates :budget, presence: true
  validates :target_number_of_participants, presence: true
  validates_numericality_of :target_number_of_participants, :only_integer => true, :greater_than_or_equal_to => 1

	def assign_address
		if_address_available = GenerateAddress.where(is_available: true)
		unless if_address_available.blank?
			begin
				WalletAddress.create(address: if_address_available.first.address, task_id: self.id)
				update_address_availability = if_address_available.first
				update_address_availability.update_attribute('is_available', 'false')
			rescue => e
				puts e.message unless Rails.env == "development"
			end
		else
			access_token = access_wallet
			Rails.logger.info access_token unless Rails.env == "development"
			api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
			secure_passphrase = SecureRandom.hex(5)
			secure_label = SecureRandom.hex(5)
			new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)
			Rails.logger.info "Wallet Passphrase #{secure_passphrase}" unless Rails.env == "development"
			new_address_id = new_address["wallet"]["id"] rescue "assigning new address ID" unless Rails.env == "development"
			puts "New Wallet Id #{new_address_id}" unless Rails.env == "development"
			new_wallet_address_sender = api.create_address(wallet_id:new_address_id, chain: "0", access_token: access_token) rescue "create address" unless Rails.env == "development"
			new_wallet_address_receiver = api.create_address(wallet_id:new_address_id, chain: "1", access_token: access_token) rescue "address receiver" unless Rails.env == "development"
			Rails.logger.info new_wallet_address_sender.inspect unless Rails.env == "development"
			Rails.logger.info new_wallet_address_receiver.inspect unless Rails.env == "development"
			Rails.logger.info "#Address #{new_wallet_address_sender["address"]}" rescue 'Address not Created'  unless Rails.env == "development"
			Rails.logger.info"#Address #{new_wallet_address_receiver["address"]}" rescue 'Address not Created' unless Rails.env == "development"
			unless new_address.blank?
				WalletAddress.create(sender_address:new_wallet_address_sender["address"], receiver_address:new_wallet_address_receiver["address"],pass_phrase:secure_passphrase , task_id: self.id, wallet_id:new_address_id)
			else
				WalletAddress.create(address:nil, task_id: self.id)
			end
		end
	end

  def funded
    budget == 0 ? "100%" : (current_fund/budget*100).round.to_s + "%"
  end

  def team_relations_string
    number_of_participants.to_s + "/" + target_number_of_participants.to_s
  end
end
