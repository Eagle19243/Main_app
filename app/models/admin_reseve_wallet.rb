class AdminReseveWallet < ActiveRecord::Base
include ApplicationHelper
 def create_we_serve_wallet
   access_token = we_serve_wallet
   Rails.logger.info access_token unless Rails.env == "development"
   api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
   secure_passphrase =  SecureRandom.hex(5)
   secure_label = SecureRandom.hex(5)
   new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)
   userKeychain = new_address["userKeychain"]
   backupKeychain = new_address["backupKeychain"]
   Rails.logger.info "Wallet Passphrase #{secure_passphrase}" unless Rails.env == "development"
   new_address_id = new_address["wallet"]["id"] rescue "assigning new address ID"
   puts "New Wallet Id #{new_address_id}" unless Rails.env == "development"
   new_wallet_address_sender = api.create_address(wallet_id: new_address_id, chain: "0", access_token: access_token) rescue "create address"
   new_wallet_address_receiver = api.create_address(wallet_id: new_address_id, chain: "1", access_token: access_token) rescue "address receiver"
   Rails.logger.info new_wallet_address_sender.inspect unless Rails.env == "development"
   Rails.logger.info new_wallet_address_receiver.inspect unless Rails.env == "development"
   Rails.logger.info "#Address #{new_wallet_address_sender["address"]}" rescue 'Address not Created'
   Rails.logger.info "#Address #{new_wallet_address_receiver["address"]}" rescue 'Address not Created'
   unless new_address.blank?
     AdminReseveWallet.create(sender_address: new_wallet_address_sender["address"], receiver_address: new_wallet_address_receiver["address"], pass_phrase: secure_passphrase, wallet_id: new_address_id, user_keys: userKeychain, backup_keys: backupKeychain)
   end
 end

end
