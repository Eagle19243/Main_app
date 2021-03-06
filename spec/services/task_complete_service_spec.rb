require 'rails_helper'

RSpec.describe TaskCompleteService, vcr: { cassette_name: 'coinbase' } do
  RSpec.shared_examples "calculating fee amounts" do
    it "sends coins to team members and to weserve" do
      mock_response = Payments::BTC::BaseTransfer::Transaction.new("123abs")
      allow_any_instance_of(Payments::BTC::InternalTransfer).to receive(:submit!).and_return(mock_response)
      service.complete!

      expect(service.task.team_memberships).to eq(task.team_memberships)
      expect(service.members_part).to eq(expected_per_member_amount)
      expect(service.we_serve_part).to eq(expected_weserve_amount)
      expect(Task.find(task.id).state).to eq("completed")
    end
  end

  describe "#initialize" do
    let(:task_attributes) do
      { budget: "0.02", current_fund: 2_000_000, state: :reviewing }
    end

    let(:task) do
      FactoryGirl.create(:task, :with_associations, :with_wallet, task_attributes)
    end

    context "with current_fund is not changed" do

      it "can be initialized with a valid instance of Task class" do
        service_object = described_class.new(task)
        expect(service_object).to be_kind_of(TaskCompleteService)
        expect(service_object.task).to eq(task)
      end

      it "prevents service initialization if wrong argument type is passed" do
        expect {
          described_class.new("fake-task-object")
        }.to raise_error(ArgumentError, "Incorrect argument type")
      end

      it "prevents service initialization if task is not in the :reviewing state" do
        invalid_task_states = %i(
          pending
          suggested_task
          accepted
          rejected
          doing
          completed
        )

        invalid_task_states.each do |state|
          task.state = state

          expect {
            described_class.new(task)
          }.to raise_error(ArgumentError, "Incorrect task state: #{state}")
        end
      end

      context "when task is fully funded" do
        let(:task_attributes) do
          { budget: "0.02", current_fund: 2_999_999, state: :reviewing }
        end

        it "allows service initialization" do
          expect {
            described_class.new(task)
          }.not_to raise_error
        end
      end

      context "when task is not fully funded" do
        let(:task_attributes) do
          { budget: "0.02", current_fund: 1_999_999, state: :reviewing }
        end

        it "prevents service initialization" do
          expect {
            described_class.new(task)
          }.to raise_error(ArgumentError, "Task fund level is too low and cannot been transfered")
        end
      end

      context "when task's budget is too low but it's fully funded" do
        let(:task_attributes) do
          { budget: "0.01", current_fund: 10_000_000, state: :reviewing }
        end

        it "prevents service initialization" do
          invalid_task = FactoryGirl.build(:task, :with_associations, :with_wallet, task_attributes)
          expect {
            described_class.new(invalid_task)
          }.to raise_error(ArgumentError, "Task's budget is too low and cannot been transfered")
        end
      end

      context "when task's balance is enough" do
        let(:task_attributes) do
          { budget: "0.02", current_fund: 2_000_000, state: :reviewing }
        end

        it "allows service initialization" do
          expect {
            described_class.new(task)
          }.not_to raise_error
        end
      end
    end

  end

  describe "#complete!", vcr: { cassette_name: 'bitgo' } do

    let(:parameters)                 { {} }
    let(:budget_in_satoshi)          { parameters[:budget] }
    let(:current_fund_in_satoshi)    { parameters[:current_fund] }
    let(:budget_in_btc)              { parameters[:budget] * 0.00000001 }
    let(:num_of_participants)        { parameters[:members] }
    let(:expected_weserve_amount)    { parameters[:weserve] }
    let(:expected_per_member_amount) { parameters[:per_member] }

    let(:task_attributes) do
      {
        state: :reviewing,
        budget: budget_in_btc,
        current_fund: current_fund_in_satoshi
      }
    end

    let(:task) do
      t = FactoryGirl.create(:task, :with_associations, :with_wallet, task_attributes)
      t.save

      t
    end

    let(:project) { task.project }
    let(:participants) { FactoryGirl.create_list(:user, num_of_participants) }
    let(:service) { described_class.new(task) }

    before do
      participants.each do |participant|
        participant.wallet = create(:wallet) unless participant.wallet
        team = Team.find_or_create_by(project_id: project.id)
        membership = TeamMembership.find_or_create_by(
          team_member_id: participant.id,
          team_id: team.id,
          role: 0
        )
        TaskMember.create(task_id: task.id, team_membership_id: membership.id)
      end
    end

    context "when there is only one task member" do
      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: 100_000_000,
            current_fund: 100_000_000,
            members: 1,
            weserve: 5_000_000,
            per_member: 95_000_000
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
            weserve: 5_000_000,
            per_member: 47_500_000
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
            weserve: 5_000_000,
            per_member: 31_666_666
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
            per_member: 100_000_000
          }
        end
      end
    end

    context "when coinbase_fee is zero" do

      it_behaves_like "calculating fee amounts" do
        let(:parameters) do
          {
            budget: 100_000_000,
            current_fund: 100_000_000,
            members: 1,
            weserve: 5_000_000,
            per_member: 95_000_000
          }
        end
      end
    end

    context "when weserve_fee and coinbase_fee are zeros" do
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
            per_member: 100_000_000
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
            weserve: 60_000,
            per_member: 1_140_000
          }
        end
      end
    end
  end
end
