class Payments::BTC::CreateWalletService

  attr_accessor :secure_passphrase, :secure_label

  def self.call(secure_passphrase, secure_label)
    self.new(secure_passphrase, secure_label).call
  end

  def initialize(secure_passphrase , secure_label)
    self.secure_passphrase = secure_passphrase
    self.secure_label = secure_label
  end

  def call
    wallet_handler = Payments::BTC::WalletHandler.new
    new_wallet_id, userKeychain, backupKeychain  = wallet_handler.create_wallet(secure_passphrase, secure_label)
    new_wallet_address_sender =  wallet_handler.create_address(new_wallet_id, "1")
    new_wallet_address_receiver = wallet_handler.create_address(new_wallet_id, "0")

    [new_wallet_id, new_wallet_address_sender, new_wallet_address_receiver, userKeychain, backupKeychain]
  end
end
