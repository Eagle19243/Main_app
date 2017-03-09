require 'rails_helper'

RSpec.shared_examples "calculating fee amounts" do
  it "sends coins to team members and to weserve" do
    expect(Payments::BTC::FeeCalculator).to receive(:estimate).and_return(100_000)
    expect(task).to receive(:transfer_to_multiple_wallets).and_return(true)
    expect(task).to receive(:build_recipients).with(
      task.team_memberships,
      expected_per_member_amount,
      expected_weserve_amount
    )

    task.transfer_task_funds
  end
end

RSpec.describe Task, :type => :model do
  describe 'state transitions' do
    describe '#reject' do
      it { is_expected.to transition_from(:pending).to(:rejected).on_event(:reject) }
      it { is_expected.to transition_from(:suggested_task).to(:rejected).on_event(:reject) }
      it { is_expected.to transition_from(:accepted).to(:rejected).on_event(:reject) }
    end
  end

  describe "transfer funds", vcr: { cassette_name: 'bitgo' } do
    let(:parameters)                 { {} }
    let(:budget_in_satoshi)          { parameters[:budget] }
    let(:current_fund_in_satoshi)    { parameters[:current_fund] }
    let(:budget_in_btc)              { parameters[:budget] * 0.00000001 }
    let(:num_of_participants)        { parameters[:members] }
    let(:expected_weserve_amount)    { parameters[:weserve] }
    let(:expected_per_member_amount) { parameters[:per_member] }

    let(:task_attributes) do
      { budget: budget_in_btc, current_fund: current_fund_in_satoshi }
    end

    let(:task) do
      FactoryGirl.create(:task, :with_associations, task_attributes)
    end

    let(:project) { task.project }
    let(:participants) { FactoryGirl.create_list(:user, num_of_participants) }

    before do
      participants.each do |participant|
        team = Team.find_or_create_by(project_id: project.id)
        membership = TeamMembership.find_or_create_by(
          team_member_id: participant.id,
          team_id: team.id,
          role: 0
        )
        TaskMember.create(task_id: task.id, team_membership_id: membership.id)

        allow(task).to receive(:update_current_fund!).and_return(true)
      end
    end

    context "when there is only one task member" do
      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: 100_000_000,
            current_fund: 100_000_000,
            members: 1,
            weserve: 4_990_005,
            per_member: 94_810_095
          }
        end
      end
    end

    context "when there are two task members" do
      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: 100_000_000,
            current_fund: 100_000_000,
            members: 2,
            weserve: 4_990_005,
            per_member: 47_405_047
          }
        end
      end
    end

    context "when there are three task members" do
      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: 100_000_000,
            current_fund: 100_000_000,
            members: 3,
            weserve: 4_990_005,
            per_member: 31_603_365
          }
        end
      end
    end

    context "when weserve_fee is zero" do
      before do
        expect(Payments::BTC::Base).to receive(:weserve_fee).and_return(0)
      end

      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: 100_000_000,
            current_fund: 100_000_000,
            members: 1,
            weserve: 0,
            per_member: 99_800_100
          }
        end
      end
    end

    context "when bitgo_fee is zero" do
      before do
        expect(Payments::BTC::Base).to receive(:bitgo_fee).and_return(0)
      end

      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: 100_000_000,
            current_fund: 100_000_000,
            members: 1,
            weserve: 4_995_000,
            per_member: 94_905_000
          }
        end
      end
    end

    context "when weserve_fee and bitgo_fee are zeros" do
      before do
        expect(Payments::BTC::Base).to receive(:weserve_fee).and_return(0)
        expect(Payments::BTC::Base).to receive(:bitgo_fee).and_return(0)
      end

      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: 100_000_000,
            current_fund: 100_000_000,
            members: 1,
            weserve: 0,
            per_member: 99_900_000
          }
        end
      end
    end

    context "minimum task budget case" do
      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: Task::MINIMUM_FUND_BUDGET,
            current_fund: Task::MINIMUM_FUND_BUDGET,
            members: 1,
            weserve: 54_945,
            per_member: 1_043_955
          }
        end
      end
    end

    context "when task budget is too low" do
      let(:parameters) do
        {
          budget: Task::MINIMUM_FUND_BUDGET - 1,
          current_fund: Task::MINIMUM_FUND_BUDGET,
          members: 1,
          weserve: 99_900,
          per_member: 1_898_100
        }
      end

      it "raises an error saying transfer is not possible" do
        expect {
          task.transfer_task_funds
        }.to raise_error(
          ArgumentError,
          "Task's budget is too low and cannot be transfered"
        )
      end
    end

    context "when task budget is ok, but current_fund is less than a budget " do
      let(:parameters) do
        {
          budget: Task::MINIMUM_FUND_BUDGET,
          current_fund: Task::MINIMUM_FUND_BUDGET - 1,
          members: 1,
          weserve: 99_900,
          per_member: 1_898_100
        }
      end

      it "raises an error saying transfer is not possible" do
        expect {
          task.transfer_task_funds
        }.to raise_error(
          ArgumentError,
          "Task fund level is too low and cannot be transfered"
        )
      end
    end

    describe "#transfer_task_funds_transaction_fee" do
      let(:min_donation_size) { Task::MINIMUM_DONATION_SIZE }

      context "when there is no extra funding over needed budget" do
        let(:extra_funding) { 0 }

        context "when there is single donation" do
          let(:donations) { 1 }

          context "when there is one task member" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 1
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(73_080)
            end
          end

          context "when there are two task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 2
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(79_200)
            end
          end

          context "when there are three task members" do
            let(:parameters) do
              {
                budget: min_donation_size * (donations + 1) - 1,
                current_fund: min_donation_size * (donations + 1) - 1,
                members: 3
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(85_320)
            end
          end
        end

        context "when there are two donations" do
          let(:donations) { 2 }

          context "when there is one task member" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 1
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(126_000)
            end
          end

          context "when there are two task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 2
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(132_120)
            end
          end
        end

        context "when there are three donations" do
          let(:donations) { 3 }

          context "when there are two task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 2
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(185_040)
            end
          end

          context "when there are three task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 3
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(191_160)
            end
          end
        end

        context "when there are 50 donations" do
          let(:donations) { 50 }

          context "when there are three task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 3
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(2_678_400)
            end
          end
        end
      end
      
      context "when there is random funding over needed budget" do
        let(:extra_funding) { rand(min_donation_size) }

        context "when there is single donation" do
          let(:donations) { 1 }

          context "when there is one task member" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 1
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(73_080)
            end
          end

          context "when there are two task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 2
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(79_200)
            end
          end

          context "when there are three task members" do
            let(:parameters) do
              {
                budget: min_donation_size * (donations + 1) - 1,
                current_fund: min_donation_size * (donations + 1) - 1,
                members: 3
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(85_320)
            end
          end
        end

        context "when there are two donations" do
          let(:donations) { 2 }

          context "when there is one task member" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 1
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(126_000)
            end
          end

          context "when there are two task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 2
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(132_120)
            end
          end
        end

        context "when there are three donations" do
          let(:donations) { 3 }

          context "when there are two task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 2
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(185_040)
            end
          end

          context "when there are three task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 3
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(191_160)
            end
          end
        end

        context "when there are 50 donations" do
          let(:donations) { 50 }

          context "when there are three task members" do
            let(:parameters) do
              {
                budget: min_donation_size * donations,
                current_fund: min_donation_size * donations + extra_funding,
                members: 3
              }
            end

            it "returns a fee" do
              fee = task.transfer_task_funds_transaction_fee
              expect(fee).to eq(2_678_400)
            end
          end
        end
      end
    end
  end
end
