module Payments::BTC
  class FundTaskFromReserveWallet
    attr_reader :task, :user, :usd_amount, :satoshi_amount,
                :stripe_token, :card_id, :save_card,
                :reserve_wallet_id, :reserve_wallet_pass_pharse,
                :skip_wallet_transaction

    MIN_AMOUNT = Task::MINIMUM_DONATION_SIZE

    def initialize(task:, user:, usd_amount:, stripe_token:, card_id:, save_card:)
      @task = task
      @user = user
      @usd_amount = usd_amount
      @satoshi_amount = calculate_satoshi_amount(usd_amount)
      @stripe_token = stripe_token
      @card_id = card_id
      @save_card = save_card

      @skip_wallet_transaction    = ENV['skip_wallet_transaction'].to_s.strip
      @reserve_wallet_id          = ENV['reserve_wallet_id'].to_s.strip
      @reserve_wallet_pass_pharse = ENV['reserve_wallet_pass_pharse'].to_s.strip

      validate_params!
    end

    def submit!
      raise_not_enough_funds_error! unless enough_balance?(satoshi_amount)
      create_task_wallet! unless task.wallet_address

      if stripe_service.charge!(amount: usd_amount, description: payment_description)
        stripe_response = JSON(stripe_service.stripe_response.to_s)

        if enabled_wallet_transactions?
          transaction = btc_transfer.submit!

          save_stripe_payment_in_db!(stripe_response, btc_transaction: transaction)
        else
          save_stripe_payment_in_db!(stripe_response, btc_transaction: nil)
        end
      else
        raise_stripe_error!(stripe_service.error)
      end
    end

    private
    def validate_params!
      raise Payments::BTC::Errors::TransferError, "Wallet transactions are not configured for this environment" unless enabled_wallet_transactions?
      raise Payments::BTC::Errors::TransferError, "Reserve Wallet ID is not configured for this environment" unless reserve_wallet_id.present?
      raise Payments::BTC::Errors::TransferError, "Reserve Wallet Passphrase is not configured for this environment" unless reserve_wallet_pass_pharse.present?
      raise Payments::BTC::Errors::TransferError, "Amount can't be blank" unless satoshi_amount > 0
      raise Payments::BTC::Errors::TransferError, "Amount can't be less than minimum donation" unless satoshi_amount >= MIN_AMOUNT
    end

    def stripe_service
      @stripe_service ||= Payments::Stripe.new(stripe_service_options)
    end

    def stripe_service_options
      if card_id
        {
          card_id: card_id,
          user: user
        }
      elsif stripe_token
        {
          stripe_token: stripe_token,
          persist_card: save_card.present?,
          user: user
        }
      end
    end

    def enabled_wallet_transactions?
      skip_wallet_transaction != "true"
    end

    def enough_balance?(amount)
      reserve_wallet_balance >= amount
    end

    def calculate_satoshi_amount(usd_amount)
      Payments::BTC::Converter.convert_usd_to_satoshi(usd_amount)
    end

    def btc_transfer
      Payments::BTC::Transfer.new(
        reserve_wallet_id,
        reserve_wallet_pass_pharse,
        task.wallet_address.receiver_address,
        satoshi_amount
      )
    end

    def payment_description
      "Payment of #{usd_amount} for task: #{task.id} for project: #{task.project_id}"
    end

    def reserve_wallet_balance
      Payments::BTC::WalletHandler.new.get_wallet_balance(reserve_wallet_id)
    end

    def save_stripe_payment_in_db!(stripe_response, btc_transaction:)
      StripePayment.create!(
        amount: usd_amount,
        amount_in_satoshi: satoshi_amount,
        task_id: task.id,
        user_id: user.id,
        stripe_token: stripe_token,
        stripe_response_id: stripe_response['id'],
        balance_transaction: stripe_response['balance_transaction'],
        paid: stripe_response['paid'],
        refund_url: stripe_response.fetch('refunds', {})['url'],
        status: stripe_response['status'],
        seller_message: stripe_response.fetch('outcome', {})['seller_message'],
        transferd: btc_transaction ? true : nil,
        tx_id:     btc_transaction.try(:tx_hash),
        tx_hex:    btc_transaction.try(:tx_hex)
      )
    end

    def create_task_wallet!
      Payments::BTC::CreateTaskWalletService.call(task.id)
      task.reload
    end

    def raise_not_enough_funds_error!
      raise Payments::BTC::Errors::TransferError,
        'Not Enough BTC in Reserve wallet Please Try Again.'
    end

    def raise_stripe_error!(message)
      raise Payments::BTC::Errors::TransferError, message
    end
  end
end
