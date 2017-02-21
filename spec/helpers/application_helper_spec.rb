require 'rails_helper'

describe ApplicationHelper do
  describe "#get_reserve_wallet_balance" do
    context "when ENV variable is nil" do
      before { stub_env('reserve_wallet_id', nil) }

      it "returns 0" do
        expect(get_reserve_wallet_balance).to eq(0)
      end
    end

    context "when ENV variable is blank" do
      before { stub_env('reserve_wallet_id', '') }

      it "returns 0" do
        expect(get_reserve_wallet_balance).to eq(0)
      end
    end

    context "when ENV variable is present", vcr: { cassette_name: 'bitgo' } do
      let(:reserve_wallet_id) { '38WXWnXa12w81VbABxJA2RS4WcRDRsf6nV'}
      before { stub_env('reserve_wallet_id', reserve_wallet_id) }

      it "returns wallet balance" do
        expect(get_reserve_wallet_balance).to eq(470975)
      end
    end
  end
end
