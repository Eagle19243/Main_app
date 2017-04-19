module Payments::BTC
  module Entities
    class WalletTransaction
      attr_reader :address_from, :address_to, :amount, :description, :status,
                  :created_at, :updated_at

      def initialize(address_from:, address_to:, amount:, description:, status:, created_at:, updated_at:)
        @address_from = address_from
        @address_to   = address_to
        @amount       = amount
        @description  = description
        @status       = status
        @created_at   = created_at
        @updated_at   = updated_at
      end

      def incoming?
        address_from.present?
      end

      def outgoing?
        !incoming?
      end

      def pending?
        !completed?
      end

      def completed?
        status == "completed"
      end
    end
  end
end
