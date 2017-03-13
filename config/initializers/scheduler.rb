require 'rufus-scheduler'
scheduler = Rufus::Scheduler::singleton
#My Jobs
scheduler.every '10m' do
  begin
    puts 'Fetching task Balance' unless Rails.env == "development"
    access_token = Payments::BTC::Base.bitgo_access_token
    api = Bitgo::V1::Api.new
    all_tasks = Task.where(state: 'accepted')
    unless all_tasks.blank?
      all_tasks.each do|task|
        wallet = task.wallet_address
        if  wallet.sender_address.present?
          response = api.get_wallet(wallet_id: wallet.wallet_id, access_token: access_token)
          task.update_attribute('current_fund',response["balance"])
        end
      end
    end
  rescue => e
    puts "Error"+e.message unless Rails.env == "development"
  end

end

scheduler.every '1d' do

  begin
    available_wallet_addresses = GenerateAddress.where(is_available:true)
    if available_wallet_addresses.blank? or available_wallet_addresses.count < 50
      #  puts 'Generating new wallet_Addresses' unless Rails.env == "development"
      access_token = Payments::BTC::Base.bitgo_access_token
      api = Bitgo::V1::Api.new
      for i in 1..5 do
        secure_passphrase = SecureRandom.hex(5)
        secure_label = SecureRandom.hex(5)
        new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)
        new_address_id = new_address["wallet"]["id"] rescue "assigning new address ID"
        new_wallet_address_sender = api.create_address(wallet_id:new_address_id, chain: "0", access_token: access_token) rescue "create address"
        new_wallet_address_receiver = api.create_address(wallet_id:new_address_id, chain: "1", access_token: access_token) rescue "address receiver"
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
            rescue => e
              puts e.message unless Rails.env == "development"
            end
          end
        end
      end
    end
  rescue => e
    puts e.message unless Rails.env == "development"
  end
end

scheduler.every '10m' do
  unless ENV['skip_wallet_transaction'] == "true"
    stripe_payments = StripePayment.where(tx_hex: nil)
    stripe_payments.each do |stripe_payment|
      task_wallet = stripe_payment.task.wallet_address.sender_address rescue nil
      unless task_wallet.blank?
        begin
          satoshi_amount = Payments::BTC::Converter.convert_usd_to_satoshi(stripe_payment.amount)
          unless satoshi_amount.eql?('error') or satoshi_amount.blank?
            access_token = Payments::BTC::Base.bitgo_reserve_access_token
            address_from = ENV['reserve_wallet_id'].strip
            sender_wallet_pass_phrase = ENV['reserve_wallet_pass_pharse'].strip
            address_to = task_wallet.strip
            api = Bitgo::V1::Api.new
            @res = api.send_coins_to_address(wallet_id: address_from, address: address_to, amount: satoshi_amount, wallet_passphrase: sender_wallet_pass_phrase, access_token: access_token)
            if @res["message"].blank?
              stripe_payment.tx_hex = @res["tx"]
              stripe_payment.tx_id = @res["hash"]
              stripe_payment.transferd = true
              stripe_payment.amount_in_satoshi = satoshi_amount
              stripe_payment.save!
            end
          end
        end
      end
    end
  end
end
