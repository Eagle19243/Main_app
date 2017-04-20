module Payments::BTC
  class FundTaskFromReserveWallet
    attr_reader :task, :user, :usd_amount, :usd_commission_amount,
                :usd_amount_to_send, :satoshi_amount,
                :stripe_token, :card_id, :save_card,
                :reserve_wallet_id, :skip_wallet_transaction

    MIN_AMOUNT = 15.0 # USD

    def initialize(task:, user:, usd_amount:, stripe_token:, card_id:, save_card:)
      @task = task
      @user = user
      @usd_amount = usd_amount
      @stripe_token = stripe_token
      @card_id = card_id
      @save_card = save_card
      @skip_wallet_transaction    = ENV['skip_wallet_transaction'].to_s.strip
      @reserve_wallet_id          = ENV['reserve_wallet_id'].to_s.strip

      validate_params!

      @usd_commission_amount = calculate_commission_amount(usd_amount)
      @usd_amount_to_send = usd_amount - usd_commission_amount
      @satoshi_amount = calculate_satoshi_amount(usd_amount_to_send)
    end

    def submit!
      if enabled_wallet_transactions?
        raise_not_enough_funds_error! unless enough_balance?(satoshi_amount)
      end

      create_task_wallet! unless task.wallet

      if stripe_service.charge!(amount: usd_amount, description: payment_description)
        stripe_response = JSON(stripe_service.stripe_response.to_s)

        if enabled_wallet_transactions?
          transaction = btc_transfer.submit!
        else
          transaction = nil
        end

        save_stripe_payment_in_db!(stripe_response, btc_transaction: transaction)
        update_task_balance!
      else
        raise_stripe_error!(stripe_service.error)
      end
    end

    private
    def validate_params!
      raise Payments::BTC::Errors::TransferError, "Environment configuration is incorrect. Please check ENV variables" if disabled_wallet_transactions? && reserve_wallet_id.present?
      raise Payments::BTC::Errors::TransferError, "Environment configuration is incorrect. Please check ENV variables" if enabled_wallet_transactions? && reserve_wallet_id.blank?
      raise Payments::BTC::Errors::TransferError, "Amount type is incorrect" unless usd_amount.is_a?(Numeric)
      raise Payments::BTC::Errors::TransferError, "Amount can't be blank" unless usd_amount > 0
      raise Payments::BTC::Errors::TransferError, "Amount can't be less than minimum donation ($#{MIN_AMOUNT})" unless usd_amount >= MIN_AMOUNT
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

    def disabled_wallet_transactions?
      !enabled_wallet_transactions?
    end

    def enough_balance?(amount)
      reserve_wallet_balance >= amount
    end

    def calculate_satoshi_amount(usd_amount)
      Payments::BTC::Converter.convert_usd_to_satoshi(usd_amount)
    end

    def calculate_commission_amount(usd_amount)
      Payments::BTC::CommissionCalculator.new(usd_amount).commission_in_usd
    end

    def btc_transfer
      Payments::BTC::InternalTransfer.new(
        reserve_wallet_id,
        task.wallet.wallet_id,
        satoshi_amount
      )
    end

    def payment_description
      "Payment of #{usd_amount} for task: #{task.id} for project: #{task.project_id}"
    end

    def reserve_wallet_balance
      wallet_handler.get_wallet_balance(reserve_wallet_id)
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
        transferd: btc_transaction ? true : false,
        tx_id: nil,
        tx_hex: nil,
        tx_internal_id: btc_transaction&.internal_id
      )
    end

    def create_task_wallet!
      Payments::BTC::CreateWalletService.call("Task", task.id)
      task.reload
    end

    def wallet_handler
      Payments::BTC::WalletHandler.new
    end

    def update_task_balance!
      balance = wallet_handler.get_wallet_balance(task.wallet.wallet_id)

      if balance > 0
        task.wallet.update_attribute(:balance, balance)
        task.update_attribute(:current_fund, balance)
      end
    end

    def raise_not_enough_funds_error!
      raise Payments::BTC::Errors::TransferError,
        'Not Enough BTC in Reserve wallet. Please Try Again'
    end

    def raise_stripe_error!(message)
      raise Payments::BTC::Errors::TransferError, message
    end
  end
end
