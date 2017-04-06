module Payments::BTC
  module Mappers
    class WalletTransaction
      attr_reader :raw_hash

      # Initialize WalletTransaction mapper
      #
      # Arguments:
      #
      #   +raw_hash+ raw hash response with transactions attributes
      #
      # Returns an instance of +WalletTransaction+ mapper
      def initialize(raw_hash)
        @raw_hash = raw_hash
      end

      # Builds an instance of +Entities::WalletTransaction+
      def build_wallet_transaction
        Entities::WalletTransaction.new(
          address_from: read_address("from"),
          address_to:   read_address("to"),
          amount:       amount_in_satoshi,
          description:  raw_hash["description"],
          status:       raw_hash["status"],
          created_at:   raw_hash["created_at"],
          updated_at:   raw_hash["updated_at"]
        )
      end

      private
      def amount_in_satoshi
        Payments::BTC::Converter.convert_btc_to_satoshi(raw_hash["amount"]["amount"])
      end

      def read_address(key)
        address_hash = raw_hash.fetch(key, {})
        return nil unless address_hash

        if address_hash["resource"] == "account"
          address_hash["id"]
        elsif address_hash["resource"] == "bitcoin_network"
          "Bitcoin network"
        else
          address_hash["address"]
        end
      end
    end
  end
end
