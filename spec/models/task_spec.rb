require 'rails_helper'

RSpec.describe Task, :type => :model, vcr: { cassette_name: 'bitgo' } do
  describe "validations" do
    it "is not possible to create a task without a deadline" do
      expect {
        create(:task, deadline: nil)
      }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Deadline can't be blank"
      )
    end

    it "is not possible to set a nil deadline for a valid task" do
      task = create(:task, deadline: "2017-03-24 11:17:46 UTC")
      task.deadline = nil
      expect(task.save).to be false
    end

    it "is possible to create a task with a deadline" do
      task = create(:task, deadline: "2017-03-24 11:17:46 UTC")
      expect(task).to be_persisted
    end
  end

  describe 'state transitions' do
    describe '#reject' do
      it { is_expected.to transition_from(:pending).to(:rejected).on_event(:reject) }
      it { is_expected.to transition_from(:suggested_task).to(:rejected).on_event(:reject) }
      it { is_expected.to transition_from(:accepted).to(:rejected).on_event(:reject) }
    end
  end

  describe 'task wallet creation' do
    it 'does not create wallet for a pending task' do
      task = create(:task, :pending)
      task.reload
      expect(task.wallet_address).not_to be_present
    end

    it 'does not create wallet for a suggested_task task' do
      task = create(:task, :suggested, user: create(:user, :confirmed_user))
      task.reload
      expect(task.wallet_address).not_to be_present
    end

    it 'does not create a wallet for a accepted task' do
      task = create(:task)
      task.reload
      expect(task.wallet_address).not_to be_present
    end

  end

  describe "transfer funds", vcr: { cassette_name: 'bitgo' } do
    let(:parameters)                 { {} }
    let(:budget_in_satoshi)          { parameters[:budget] }
    let(:current_fund_in_satoshi)    { parameters[:current_fund] }
    let(:budget_in_btc)              { parameters[:budget] * 0.00000001 }
    let(:num_of_participants)        { parameters[:members] }

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
