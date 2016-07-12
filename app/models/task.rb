class Task < ActiveRecord::Base
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
	after_create :assign_address
	aasm :column => 'state', :whiny_transitions => false do
    state :pending
    state :accepted
    state :rejected      
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
				puts e.message
			end
		else
			access_token = access_wallet
			Rails.logger.info access_token
			api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
			secure_passphrase = SecureRandom.hex(5)
			secure_label = SecureRandom.hex(5)
			new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)
			Rails.logger.info "Wallet Passphrase #{secure_passphrase}"
			new_address_id = new_address["wallet"]["id"] rescue nil
			puts "New Wallet Id #{new_address_id}"
			new_wallet_address_sender = api.create_address(wallet_id:new_address_id, chain: "0", access_token: access_token) rescue nil
			new_wallet_address_receiver = api.create_address(wallet_id:new_address_id, chain: "1", access_token: access_token) rescue nil
			Rails.logger.info new_wallet_address_sender.inspect
			Rails.logger.info new_wallet_address_receiver.inspect
			Rails.logger.info "#Address #{new_wallet_address_sender["address"]}" rescue 'Address not Created'
			Rails.logger.info"#Address #{new_wallet_address_receiver["address"]}" rescue 'Address not Created'
			unless new_address.blank? or new_address.blank?
				WalletAddress.create(sender_address:new_wallet_address_sender["address"], receiver_address:new_wallet_address_receiver["address"],pass_phrase:secure_passphrase , task_id: self.id, wallet_id:new_address_id)
			else
				WalletAddress.create(address:nil, task_id: self.id)
			end
		end
	end


end
