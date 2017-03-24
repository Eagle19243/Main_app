class TaskDestroyService
  attr_reader :task, :user

  def initialize(task, user)
    raise ArgumentError, "Incorrect argument type" unless task.is_a?(Task)
    raise ArgumentError, "Incorrect argument type" unless user.is_a?(User)

    @task = task
    @user = user
  end

  def destroy_task
    update_current_fund! if task.wallet_address
    return false if task_has_funding?

    ActiveRecord::Base.transaction do
      if task.destroy
        user.create_activity(task, 'deleted')
        true
      else
        false
      end
    end
  end

  private
  def wallet_handler
    Payments::BTC::WalletHandler.new
  end

  def update_current_fund!
    balance = wallet_handler.get_wallet_balance(task.wallet_address.wallet_id)
    task.update_attribute(:current_fund, balance)
  end

  def task_has_funding?
    task.current_fund > 0
  end
end
