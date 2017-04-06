require 'rails_helper'

RSpec.describe Payments::BTC::MultiRecipientsTransfer do
  describe '#submit!' do
    let(:recipients) do
      [
        { address: 'test-address-to-1', amount: 100_000 },
        { address: 'test-address-to-2', amount: 500_000 },
      ]
    end
    let(:transfer) do
      described_class.new(create(:wallet), recipients)
    end

    context "when response is successful" do
      it "returns transaction object" do
        mock_response = Payments::BTC::BaseTransfer::Transaction.new("123abs")
        allow_any_instance_of(Payments::BTC::InternalTransfer).to receive(:submit!).and_return(mock_response)

        transactions = transfer.submit!
        expect(transactions.map(&:internal_id)).to eq ["123abs", "123abs"]
      end
    end
  end
end
