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
          expect(transaction).to be_completed
          expect(transaction).not_to be_pending
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
          expect(transaction).to be_completed
          expect(transaction).not_to be_pending
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
        end
      end
    end

    describe "incoming unconfirmed transaction from btc network" do
      let(:hash) do
        {
          "id" => "5a984ed1-7ecd-53e6-974f-2c12c7af84a7",
          "type" => "send",
          "status" => "pending",
          "amount" => {
            "amount" => "0.00222072",
            "currency" => "BTC"
          },
          "native_amount" => {
            "amount"=>"2.63",
            "currency"=>"USD"
          },
          "description" => nil,
          "created_at" => "2017-03-28T04:03:56Z",
          "updated_at" => "2017-03-28T04:03:56Z",
          "resource" => "transaction",
          "resource_path" => "/v2/accounts/4060e15e-7fad-5a22-8816-80c192e10a7a/transactions/5a984ed1-7ecd-53e6-974f-2c12c7af84a7",
          "instant_exchange" => false,
          "network" => {
            "status" => "unconfirmed",
            "hash" => "e530f349a3c06c3a8677805b95eb2eb178eb29e8951e9c531e4638579071f9a1"
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
          expect(transaction.amount).to eq(222071)
          expect(transaction.description).to be_nil
          expect(transaction.status).to eq("pending")
          expect(transaction).not_to be_completed
          expect(transaction).to be_pending
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
          expect(transaction).to be_completed
          expect(transaction).not_to be_pending
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
          expect(transaction).to be_completed
          expect(transaction).not_to be_pending
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
        end
      end
    end

    describe "outgoing unconfirmed transaction to btc address" do
      let(:hash) do
        {
          "id" => "cfe0d9ae-36a6-58bd-8e4a-533176d12fec",
          "type" => "send",
          "status" => "pending",
          "amount" => {
            "amount" => "-0.00354240",
            "currency"=>"BTC"
          },
          "native_amount" => {
            "amount" => "-4.18",
            "currency"=>"USD"
          },
          "description" => "External transfer from 4060e15e-7fad-5a22-8816-80c192e10a7a to 3JGZHVSntQDrV862ZzgverUwdi1oNXSNXr",
          "created_at" => "2017-03-28T04:03:56Z",
          "updated_at" => "2017-03-28T04:03:56Z",
          "resource" => "transaction",
          "resource_path" => "/v2/accounts/4060e15e-7fad-5a22-8816-80c192e10a7a/transactions/cfe0d9ae-36a6-58bd-8e4a-533176d12fec",
          "instant_exchange" => false,
          "network" => {
            "status" => "unconfirmed",
            "hash" => "e2a1de71956a8ed8938b1a540875090b5f4bf581a07a8e67e4d5245aa5786537",
            "transaction_fee" => {
              "amount" => "0.00054240",
              "currency" => "BTC"
            },
            "transaction_amount" => {
              "amount" => "0.00300000",
              "currency" => "BTC"
            }
          },
          "to" => {
            "resource" => "bitcoin_address",
            "address" => "3JGZHVSntQDrV862ZzgverUwdi1oNXSNXr"
          },
          "details" => {
            "title" => "Sent bitcoin",
            "subtitle" => "to Bitcoin address"
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
          expect(transaction).to be_outgoing
          expect(transaction).not_to be_incoming
          expect(transaction.address_from).to be_nil
          expect(transaction.address_to).to eq("3JGZHVSntQDrV862ZzgverUwdi1oNXSNXr")
          expect(transaction.amount).to eq(-354240)
          expect(transaction.description).to eq("External transfer from 4060e15e-7fad-5a22-8816-80c192e10a7a to 3JGZHVSntQDrV862ZzgverUwdi1oNXSNXr")
          expect(transaction.status).to eq("pending")
          expect(transaction).not_to be_completed
          expect(transaction).to be_pending
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
          expect(transaction.created_at).to eq("2017-03-28T04:03:56Z")
        end
      end
    end
  end
end
