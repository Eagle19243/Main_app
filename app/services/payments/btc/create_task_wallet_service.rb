class Payments::BTC::CreateTaskWalletService

  attr_accessor :task

  def self.call(task_id)
    self.new(task_id).call
  end

  def initialize(task_id)
    self.task = Task.find(task_id)
  end

  def call
    secure_passphrase = SecureRandom.hex(5)
    secure_label = SecureRandom.hex(5)

    wallet_creation_service = Payments::BTC::CreateWalletService.new(secure_passphrase, secure_label)
    new_wallet_id, new_wallet_address_sender, new_wallet_address_receiver, userKeychain, backupKeychain = wallet_creation_service.call
    byebug
    WalletAddress.create(sender_address: new_wallet_address_sender, receiver_address: new_wallet_address_receiver, pass_phrase: secure_passphrase, task_id: task.id, wallet_id: new_wallet_id)
  end

end
