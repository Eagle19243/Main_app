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

    wallet_creation_service = Payments::BTC::CreateWalletService.new(secure_passphrase, secure_label)
    new_wallet_id, new_wallet_address_sender, new_wallet_address_receiver, userKeychain, backupKeychain = wallet_creation_service.call
    
    UserWalletAddress.create(sender_address: new_wallet_address_sender, receiver_address: new_wallet_address_receiver, pass_phrase: secure_passphrase, user_id: user.id, wallet_id: new_wallet_id, user_keys: userKeychain, backup_keys: backupKeychain)
  end
end
