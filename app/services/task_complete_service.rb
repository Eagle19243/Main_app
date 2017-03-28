class TaskCompleteService
  attr_reader :task

  def initialize(task)
    @task = task

    raise ArgumentError, "Incorrect argument type" unless task.is_a?(Task)
    raise ArgumentError, "Incorrect task state: #{task.state}" unless task.reviewing?

    update_current_fund!
    raise ArgumentError, "Task's budget is too low and cannot been transfered"   if task.satoshi_budget < Task::MINIMUM_FUND_BUDGET
    raise ArgumentError, "Task fund level is too low and cannot been transfered" if task.current_fund < task.satoshi_budget
    raise ArgumentError, "Task's wallet doesn't exist" unless task.wallet_address
  end

  def complete!
    ActiveRecord::Base.transaction do
      mark_task_as_completed!
      transaction = send_funds_to_recipients!(recipients, transaction_fee)
      create_wallet_transactions_in_db!(recipients, transaction)
    end
  end

  def we_serve_part
    @we_serve_part ||= (amount_to_send * Payments::BTC::Base.weserve_fee).to_i
  end

  def members_part
    @members_part ||= ((amount_to_send - we_serve_part) / task.team_memberships.size).to_i
  end

  def recipients
    @recipients ||= build_recipients
  end

  private
  def mark_task_as_completed!
    task.complete!
  end

  def wallet_handler
    @wallet_handler ||= Payments::BTC::WalletHandler.new
  end

  def update_current_fund!
    if wallet_handler.wallet_balance_confirmed?(task.wallet_address.wallet_id)
      balance = wallet_handler.get_wallet_balance(task.wallet_address.wallet_id)
      task.update_attribute(:current_fund, balance)
    else
      raise Payments::BTC::Errors::TransferError,
        "Task's wallet appears to have pending transactions. If someone recently transferred fund on task's wallet, then it needs time to be approved. If this is the case, please try again later"
    end
  end

  def amount_to_send
    @amount_to_send ||= amount_after_bitgo_fee(task.current_fund - transaction_fee)
  end

  def amount_after_bitgo_fee(amount)
    (amount - (amount * Payments::BTC::Base.bitgo_fee))
  end

  def transaction_fee
    @transaction_fee ||= task.transfer_task_funds_transaction_fee
  end

  def build_recipients
    recipients = task.team_memberships.map do |membership|
      {
        address: membership.team_member.user_wallet_address.receiver_address,
        amount: members_part
      }
    end

    if we_serve_part > 0
      recipients << {
        address: Payments::BTC::Base.weserve_wallet_address,
        amount: we_serve_part
      }
    end

    recipients
  end

  def send_funds_to_recipients!(recipients, fee)
    transfer = Payments::BTC::MultiRecipientsTransfer.new(
      task.wallet_address.wallet_id,
      task.wallet_address.pass_phrase,
      recipients,
      fee
    )
    transfer.submit!
  end

  def create_wallet_transactions_in_db!(recipients, transaction)
    recipients.map do |recipient|
      WalletTransaction.create!(
        tx_hex: transaction.tx_hex,
        tx_id: transaction.tx_hash,
        amount: recipient[:amount],
        user_wallet: recipient[:address],
        task_id: task.id
      )
    end
  end
end
