class Payments::BTC::CreateUserWalletService

  attr_accessor :user

  def self.call(user_id)
    self.new(user_id).call
  end

  def initialize(user_id)
    self.user = User.find(user_id)
  end

  def call
    secure_passphrase =  user.encrypted_password
    secure_label = SecureRandom.hex(5)

    wallet_handler = Payments::BTC::WalletHandler.new
    new_wallet_id, userKeychain, backupKeychain  = wallet_handler.create_wallet(secure_passphrase, secure_label)

    new_wallet_address_sender =  wallet_handler.create_address(new_wallet_id, "1")
    new_wallet_address_receiver = wallet_handler.create_address(new_wallet_id, "0")
    UserWalletAddress.create(sender_address: new_wallet_address_sender, receiver_address: new_wallet_address_receiver, pass_phrase: secure_passphrase, user_id: user.id, wallet_id: new_wallet_id, user_keys: userKeychain, backup_keys: backupKeychain)
  end
end
