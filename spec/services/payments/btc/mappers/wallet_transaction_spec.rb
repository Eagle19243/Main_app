require 'rails_helper'

RSpec.describe Payments::BTC::Mappers::WalletTransaction do
  let(:hash) do
    {
      "id" => "5ecbce9f-1833-5bc2-8809-e9d9561d36e3",
      "type" => "transfer",
      "status" => "completed",
      "amount" => {
        "amount" => "0.00141545",
        "currency" => "BTC"
      },
      "native_amount" => {
        "amount" => "1.47",
        "currency" => "USD"
      },
      "description" => "Yes",
      "created_at" => "2017-03-28T04:03:56Z",
      "updated_at" => "2017-03-28T04:03:56Z",
      "resource" => "transaction",
      "resource_path":"/v2/accounts/test-account-id/transactions/5ecbce9f-1833-5bc2-8809-e9d9561d36e3",
      "instant_exchange" => false,
      "details" => {
        "title" => "Transferred bitcoin",
        "subtitle" => "from Ruslan Sharipov"
      }
    }
  end

  describe "#build_wallet_transaction" do
    describe "incoming transaction from account" do
      let(:incoming_tx_hash) do
        hash.merge(
          "from" => {
            "id" => "5c8e0eba-5e40-5094-88eb-d00089b62826",
            "resource" => "account",
            "resource_path" => "/v2/accounts/5c8e0eba-5e40-5094-88eb-d00089b62826"
          }
        )
      end

      it "builds an instance of wallet transaction object" do
        mapper = described_class.new(incoming_tx_hash)
        transaction = mapper.build_wallet_transaction

        aggregate_failures("transaction object is correct") do
          expect(transaction).to be_kind_of(
            Payments::BTC::Entities::WalletTransaction
          )
          expect(transaction).to be_incoming
          expect(transaction).not_to be_outgoing
          expect(transaction.address_from).to eq("5c8e0eba-5e40-5094-88eb-d00089b62826")
          expect(transaction.address_to).to be_nil
          expect(transaction.amount).to eq(141545)
          expect(transaction.description).to eq("Yes")
          expect(transaction.status).to eq("completed")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
        end
      end
    end

    describe "incoming transaction from btc network" do
      let(:hash) do
        {
          "id" => "9bc90ef1-b587-59d9-bfe0-404d84de1113",
          "type" => "send",
          "status" => "completed",
          "amount" => {
            "amount" => "0.00158811",
            "currency" => "BTC"
          },
          "native_amount" => {
            "amount" => "1.84",
             "currency" => "USD"
          },
           "description" => nil,
           "created_at" => "2017-03-28T04:03:56Z",
           "updated_at" => "2017-03-28T04:03:56Z",
           "resource" => "transaction",
           "resource_path" => "/v2/accounts/4060e15e-7fad-5a22-8816-80c192e10a7a/transactions/9bc90ef1-b587-59d9-bfe0-404d84de1113",
           "instant_exchange" => false,
           "network" => {
             "status" => "confirmed",
             "hash" => "11ad3fdcaf57f2a91fd24c75033097abe193062bc32ad88c39f0484839b216b0"
           },
           "from" => {
             "resource" => "bitcoin_network"
           },
           "details" => {
             "title" => "Received bitcoin",
             "subtitle" => "from Bitcoin address"
           }
        }
      end

      it "builds an instance of wallet transaction object" do
        mapper = described_class.new(hash)
        transaction = mapper.build_wallet_transaction

        aggregate_failures("transaction object is correct") do
          expect(transaction).to be_kind_of(
            Payments::BTC::Entities::WalletTransaction
          )
          expect(transaction).to be_incoming
          expect(transaction).not_to be_outgoing
          expect(transaction.address_from).to eq("Bitcoin network")
          expect(transaction.address_to).to be_nil
          expect(transaction.amount).to eq(158811)
          expect(transaction.description).to be_nil
          expect(transaction.status).to eq("completed")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
        end
      end
    end

    describe "outgoing transaction to account" do
      let(:outgoing_tx_hash) do
        hash.merge(
          "to" => {
            "id" => "5c8e0eba-5e40-5094-88eb-d00089b62826",
            "resource" => "account",
            "resource_path" => "/v2/accounts/5c8e0eba-5e40-5094-88eb-d00089b62826"
          }
        )
      end

      it "builds an instance of wallet transaction object" do
        mapper = described_class.new(outgoing_tx_hash)
        transaction = mapper.build_wallet_transaction

        aggregate_failures("transaction object is correct") do
          expect(transaction).to be_kind_of(
            Payments::BTC::Entities::WalletTransaction
          )
          expect(transaction).not_to be_incoming
          expect(transaction).to be_outgoing
          expect(transaction.address_from).to be_nil
          expect(transaction.address_to).to eq("5c8e0eba-5e40-5094-88eb-d00089b62826")
          expect(transaction.amount).to eq(141545)
          expect(transaction.description).to eq("Yes")
          expect(transaction.status).to eq("completed")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
        end
      end
    end

    describe "outgoing transaction to btc address" do
      let(:outgoing_tx_hash) do
        hash.merge(
          "to" => {
            "resource" => "bitcoin_address",
            "address"=>"3ERiaZovXnWxjRbz8m2nuTBakRUsHCqSMV"
          }
        )
      end

      it "builds an instance of wallet transaction object" do
        mapper = described_class.new(outgoing_tx_hash)
        transaction = mapper.build_wallet_transaction

        aggregate_failures("transaction object is correct") do
          expect(transaction).to be_kind_of(
            Payments::BTC::Entities::WalletTransaction
          )
          expect(transaction).not_to be_incoming
          expect(transaction).to be_outgoing
          expect(transaction.address_from).to be_nil
          expect(transaction.address_to).to eq("3ERiaZovXnWxjRbz8m2nuTBakRUsHCqSMV")
          expect(transaction.amount).to eq(141545)
          expect(transaction.description).to eq("Yes")
          expect(transaction.status).to eq("completed")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
        end
      end
    end
  end
end
