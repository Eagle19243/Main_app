require 'rufus-scheduler'
include ApplicationHelper
scheduler = Rufus::Scheduler::singleton
 #My Jobs
scheduler.every '2m' do

  begin
    puts 'Fetching task Balance' unless Rails.env == "development"
    access_token= access_wallet
    api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)

  #  puts 'initializebitgo' unless Rails.env == "development"

   # puts api.inspect unless Rails.env == "development"
    # puts wallet.inspect
  #  puts 'inspecting' unless Rails.env == "development"
    all_tasks = Task.where(state: 'accepted')
    unless all_tasks.blank?
      all_tasks.each do|task|
       wallet = task.wallet_address
        if  wallet.sender_address.present?
          response = api.get_wallet(wallet_id: wallet.wallet_id, access_token: access_token)
         # puts response.inspect
          task.update_attribute('current_fund',response["balance"])
         # puts " Sucessfully updated This #{task.title} with balance #{response["balance"]}"
        end
      end
    end
      #   batch_of_addresses.each do|this_address|
    #ActiveRecord::Base.logger.silence do
      # do a lot of querys without noisy logs
     # batch_of_addresses = WalletAddress.all
    #end

    # puts batch_of_addresses
    # unless batch_of_addresses.blank?
    #   batch_of_addresses.each do|this_address|
    #     wallet_found = WalletAddress.where(sender_address: this_address.sender_address).first rescue nil
    #     if(wallet_found)
    #       response = api.get_wallet(wallet_id:this_address.wallet_id, access_token: access_token)
    #       puts response.inspect unless Rails.env == "development"
    #       # current_amount = this_address['balance'].to_i
    #       # current_amount = current_amount/(10**8).to_f rescue 0.0
    #       #wallet_found.update_attribute('current_balance',response["balance"])
    #       this_address.task.update_attribute('current_fund',response["balance"])
    #       puts " Sucessfully updated This #{this_address.sender_address} with balance #{response["balance"]} " unless Rails.env == "development"
    #     end
    #   end
    # end
  rescue => e
    puts "Error"+e.message unless Rails.env == "development"
  end

end



scheduler.every '1d' do

begin
  available_wallet_addresses = GenerateAddress.where(is_available:true)
  if available_wallet_addresses.blank? or available_wallet_addresses.count < 50
  #  puts 'Generating new wallet_Addresses' unless Rails.env == "development"
    access_token = access_wallet
    api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
    for i in 1..5 do
      secure_passphrase = SecureRandom.hex(5)
      secure_label = SecureRandom.hex(5)
      new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)
    #  Rails.logger.info "Wallet Passphrase #{secure_passphrase}" unless Rails.env == "development"
      new_address_id = new_address["wallet"]["id"] rescue "assigning new address ID"
   #   puts "New Wallet Id #{new_address_id}" unless Rails.env == "development"
      new_wallet_address_sender = api.create_address(wallet_id:new_address_id, chain: "0", access_token: access_token) rescue "create address"
      new_wallet_address_receiver = api.create_address(wallet_id:new_address_id, chain: "1", access_token: access_token) rescue "address receiver"
    #  Rails.logger.info new_wallet_address_sender.inspect unless Rails.env == "development"
     # Rails.logger.info new_wallet_address_receiver.inspect unless Rails.env == "development"
     # Rails.logger.info "#Address #{new_wallet_address_sender["address"]}" rescue 'Address not Created'  unless Rails.env == "development"
     # Rails.logger.info"#Address #{new_wallet_address_receiver["address"]}" rescue 'Address not Created' unless Rails.env == "development"
      unless new_address.blank? or new_address["wallet"]["id"].blank?
        GenerateAddress.create(sender_address:new_wallet_address_sender["address"], receiver_address:new_wallet_address_receiver["address"],pass_phrase:secure_passphrase , wallet_id:new_address_id ,is_available:true)

      end
    end

    #puts 'Missing task address inspection and Address Assignment!!' unless Rails.env == "development"
    tasks_without_wallets = WalletAddress.where(sender_address:nil)
    unless tasks_without_wallets.blank?
      tasks_without_wallets.each do|missing_task_wallet|
        if_address_available = GenerateAddress.where(is_available: true)
        unless if_address_available.blank?
          begin
            missing_task_wallet.update_attribute(:sender_address => if_address_available.first.sender_address,:receiver_address => if_address_available.first.receiver_address , :pass_phrase => if_address_available.first.pass_phrase,:wallet_id => if_address_available.first.wallet_id)
            update_address_availability = if_address_available.first
            update_address_availability.update_attribute('is_available', 'false')
     #       puts 'Missing task Addressed Fixed.' unless Rails.env == "development"
          rescue => e
            puts e.message unless Rails.env == "development"
          end
        end
      end
    end

  else
    # puts "System has #{available_wallet_addresses.count} Wallet Address Avaliable, No need to generate more Addresses." unless Rails.env == "development"
  end
rescue => e
  puts e.message unless Rails.env == "development"
end
end
