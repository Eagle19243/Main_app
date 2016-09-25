class WalletTransactionsController < ApplicationController
    before_action :authenticate_user!

    def new
      @task=Task.find( params['id']) rescue nil
      if( @task.nil? )
        redirect_to '/', alert: 'Invalid Task Id'
      end
      if @task.suggested_task?
        flash[:error] = "You can not Apply For Suggested Task "
        redirect_to task_path(@task.id)
      end
      @wallet_transaction=WalletTransaction.new
    end

    def create
      transfering_task=Task.find( params['task_id']) rescue nil
      if( transfering_task.nil? )
        redirect_to '/', alert: 'Trying to create Transaction With invalid Task Id'
      end
      begin
        @transfer = WalletTransaction.new(amount:params['amount'] ,user_wallet:params['wallet_transaction_user_wallet'] ,task_id: params['task_id'])
        satoshi_amount = nil
        satoshi_amount = convert_usd_to_btc_and_then_satoshi(params['amount']) if @transfer.valid?
        if satoshi_amount.eql?('error') or satoshi_amount.blank?
         # satoshi_amount=150761.0
           respond_to do |format|
             format.html { redirect_to wallet_transactions_new_path +'?id='+transfering_task.id.to_s  , alert: 'Error, Please try again Later!' }
          end
        else
          access_token = access_wallet
          address_from = transfering_task.wallet_address.wallet_id
          sender_wallet_pass_phrase = transfering_task.wallet_address.pass_phrase
          address_to = params['wallet_transaction_user_wallet'].strip
          api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
          @res = api.send_coins_to_address(wallet_id: address_from, address: address_to, amount:satoshi_amount , wallet_passphrase: sender_wallet_pass_phrase, access_token: access_token)
          unless @res["message"].blank?
            respond_to do |format|
              format.html {redirect_to wallet_transactions_new_path+'?id='+transfering_task.id.to_s  , alert: @res["message"] }
            end
          else
            @transfer.tx_hash = @res["tx"]
            @transfer.task_id = transfering_task.id

            if(@transfer.save!)
              respond_to do |format|
                format.html {redirect_to wallet_transactions_new_path+'?id='+transfering_task.id.to_s  , notice: " #{params["amount"]} usd has been successfully sent to #{@transfer.user_wallet}." }

              end
            else
              respond_to do |format|
                format.html { redirect_to wallet_transactions_new_path+'?id='+transfering_task.id.to_s  , alert: @transfer.errors.messages.inspect }
              end
            end
         end
        end
      rescue => e
        respond_to do |format|
          format.html { redirect_to wallet_transactions_new_path+'?id='+transfering_task.id.to_s  , alert: e.inspect }
        end
      end

    end
  

end
