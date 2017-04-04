require 'rails_helper'

RSpec.describe Payments::BTC::FundBtcAddress do
  let!(:user) { create(:user) }
  let!(:wallet) { create(:wallet, wallet_id: "30a21ed2-4f04-57ae-9d21-becb751138f4", wallet_owner_id: user.id, wallet_owner_type: 'User') }
  let(:amount) { described_class::MIN_AMOUNT }
  let(:address_to) { 'btc-address' }

  before do
    user.reload
  end

  describe "#initialize" do
    context "when arguments are invalid" do
      it "raises an error if user argument is incorrect" do
        fake_user = "fake user"

        expect {
          described_class.new(
            amount: amount,
            address_to: address_to,
            user: fake_user
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "User argument is invalid"
        )
      end

      it "raises an error if user has no wallet" do
        bad_user = create(:user)

        expect {
          described_class.new(
            amount: amount,
            address_to: address_to,
            user: bad_user
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "User's wallet doesn't exist"
        )
      end

      it "raises an error if amount is zero" do
        invalid_amount = 0

        expect {
          described_class.new(
            amount: invalid_amount,
            address_to: address_to,
            user: user
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Amount can't be blank"
        )
      end

      it "raises an error if amount is less than minimum" do
        invalid_amount = amount - 1

        expect {
          described_class.new(
            amount: invalid_amount,
            address_to: address_to,
            user: user
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Amount can't be less than 0.001 BTC"
        )
      end

      it "raises an error receiver_address is blank" do
        invalid_address = nil

        expect {
          described_class.new(
            amount: amount,
            address_to: invalid_address,
            user: user
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Recieve address can't be blank"
        )
      end
    end

    context "when arguments are valid" do
      context "and when transfer is successful", vcr: { cassette_name: 'coinbase/send/success' } do
        it "creates transaction record in database" do
          service = described_class.new(
            amount: amount,
            address_to: address_to,
            user: user
          )

          expect(UserWalletTransaction.count).to eq(0)

          service.submit!

          expect(UserWalletTransaction.count).to eq(1)

          transaction = UserWalletTransaction.first

          aggregate_failures("db record is correct") do
            expect(transaction.amount).to eq(amount)
            expect(transaction.user_wallet).to eq(address_to)
            expect(transaction.user_id).to eq(user.id)
            expect(transaction.tx_internal_id).to eq(
              "b6af30cc-5e85-5ab3-a965-8c181cc48434"
            )
          end
        end
      end

      context "and when transfer is not successful", vcr: { cassette_name: 'coinbase/send/insufficient_funds' } do
        it "fails" do
          service = described_class.new(
            amount: amount,
            address_to: address_to,
            user: user
          )

          expect {
            service.submit!
          }.to raise_error(
            Payments::BTC::Errors::TransferError,
            "You don't have that much."
          )
        end
      end
    end
  end
end
