class TaskCompleteService
  attr_reader :task

  def initialize(task)
    @task = task

    raise ArgumentError, "Incorrect argument type" unless task.is_a?(Task)
    raise ArgumentError, "Incorrect task state: #{task.state}" unless task.reviewing?

    update_current_fund!
    raise ArgumentError, "Task's budget is too low and cannot been transfered"   if task.satoshi_budget < Task::MINIMUM_FUND_BUDGET
    raise ArgumentError, "Task fund level is too low and cannot been transfered" if task.current_fund < task.satoshi_budget
    raise ArgumentError, "Task's wallet doesn't exist" unless task.wallet.wallet_id
  end

  def complete!
    ActiveRecord::Base.transaction do
      mark_task_as_completed!
      transactions = send_funds_to_recipients!(recipients)
      create_wallet_transactions_in_db!(recipients, transactions)
    end
  end

  def amount
    task.current_fund
  end

  def we_serve_part
    @we_serve_part ||= (amount * Payments::BTC::Base.weserve_fee).to_i
  end

  def members_part
    @members_part ||= ((amount - we_serve_part) / task.team_memberships.size).to_i
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
    balance = wallet_handler.get_wallet_balance(task.wallet.wallet_id)
    if balance > 0
      task.update_attribute(:current_fund, balance)
    else
      raise Payments::BTC::Errors::TransferError,
        "Task's wallet appears to have pending transactions. If someone recently transferred fund on task's wallet, then it needs time to be approved. If this is the case, please try again later"
    end
  end

  def build_recipients
    recipients = task.team_memberships.map do |membership|
      {
        address: membership.team_member.wallet.wallet_id,
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

  def send_funds_to_recipients!(recipients)
    transfer_service = Payments::BTC::MultiRecipientsTransfer.new(
      task.wallet.wallet_id,
      recipients
    )
    transfer_service.submit!
  end

  def create_wallet_transactions_in_db!(recipients, transactions)
    recipients.each_with_index do |recipient, index|
      WalletTransaction.create!(
        task_id: task.id,
        user_wallet: transactions[index].internal_id,
        amount: recipient[:amount]

      )
    end
  end
end
