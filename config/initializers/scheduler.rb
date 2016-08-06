require 'rufus-scheduler'
include ApplicationHelper
scheduler = Rufus::Scheduler::singleton
 #My Jobs
scheduler.every '30s' do

  begin
    puts 'Fetching user Balance'
    access_token= access_wallet
    api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)

    puts 'initializebitgo'

    puts api.inspect
    # puts wallet.inspect
    puts 'inspecting'
    batch_of_addresses = WalletAddress.all
    # puts batch_of_addresses
    unless batch_of_addresses.blank?
      batch_of_addresses.each do|this_address|
        wallet_found = WalletAddress.where(sender_address: this_address.sender_address).first rescue nil
        if(wallet_found)
          response = api.get_wallet(wallet_id:this_address.wallet_id, access_token: access_token)
          puts response.inspect
          # current_amount = this_address['balance'].to_i
          # current_amount = current_amount/(10**8).to_f rescue 0.0
          wallet_found.update_attribute('current_balance',response["balance"])
          puts " Sucessfully updated This #{this_address.sender_address} with balance #{response["balance"]} "
        end
      end
    end
  rescue => e
    puts "Error"+e.message
  end

end



scheduler.every '1d' do

begin
  available_wallet_addresses = GenerateAddress.where(is_available:true)
  if available_wallet_addresses.blank? or available_wallet_addresses.count < 50
    puts 'Generating new wallet_Addresses'
    wallet = access_wallet
    api = Bitgo::V1::Api.new(Bitgo::V1::Api::LIVE)
    for i in 1..5 do
      secure_passphrase = SecureRandom.hex(5)
      secure_label = SecureRandom.hex(5)
      new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: wallet["access_token"])
      puts "#{i} Bitgo Wallet_id #{new_address["wallet"]["id"]}"
      puts "#{i} Bitgo Wallet_Address #{new_address["wallet"]["id"]}"
      unless new_address.blank? or new_address["wallet"]["id"].blank?
        GenerateAddress.create!(address: new_address["wallet"]["address"],wallet_id:new_address["wallet"]["id"], is_available:true)
      end
    end

    # Assign Wallet addresses to users having no address attached

    puts 'Missing user address inspection and Address Assignment!!'
    users_without_wallets = WalletAddress.where(address:nil)
    unless users_without_wallets.blank?
      users_without_wallets.each do|missing_user_wallet|
        if_address_available = GenerateAddress.where(is_available: true)
        unless if_address_available.blank?
          begin
            missing_user_wallet.update_attribute('address', if_address_available.first.address)
            update_address_availability = if_address_available.first
            update_address_availability.update_attribute('is_available', 'false')
            puts 'Missing user Addressed Fixed.'
          rescue => e
            puts e.message
          end
        end
      end
    end

  else
    puts "System has #{available_wallet_addresses.count} Wallet Address Avaliable, No need to generate more Addresses."
  end
rescue => e
  puts e.message
end
end