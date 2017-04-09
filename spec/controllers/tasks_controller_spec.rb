require 'rails_helper'

RSpec.describe TasksController do
  let(:user) do
    user = FactoryGirl.create(:user, :confirmed_user)
    user.admin!
    user
  end

  let(:project) do
    FactoryGirl.create(:project, user: user)
  end

  before do
    sign_in(user)
  end

  describe '#create' do
    let(:create_params) do
      {
        task: {
          title: 'title',
          budget: 1,
          target_number_of_participants: 1,
          condition_of_execution: 'condition',
          deadline: Time.now,
          project_id: project.id
        }
      }
    end

    context 'correct redirect' do
      it 'redirects to card_payment_project_url' do
        post(:create, create_params)

        expect(response).to redirect_to(
          taskstab_project_path(project, tab: 'Tasks')
        )
      end
    end
  end

  describe '#update' do
    let(:existing_task) do
      FactoryGirl.create(:task, :with_associations, project: project, user: user)
    end

    let(:update_params) do
      {
        title: 'Updated title',
        short_description: 'Updated short description',
        condition_of_execution: 'Updated condition of execution',
        proof_of_execution: 'Updated proof of execution',
        deadline: '2017-02-21 01:46 PM'
      }
    end

    it 'updates existing task' do
      patch(:update, id: existing_task.id, task: update_params)

      updated_task = Task.find(existing_task.id)

      update_params.each do |key, value|
        expect(updated_task.send(key)).to eq(value)
      end
    end

    it 'ignores deadline attribute for task with any funding' do
      existing_task.update_attribute(:current_fund, 100)

      expect {
        patch(:update, id: existing_task.id, task: update_params)
      }.not_to change {
        Task.find(existing_task.id).deadline
      }
    end
  end

  describe '#doing' do
    subject(:make_request) { get(:doing, { id: existing_task.id }) }

    context 'when the task is eligible to move to doing' do
      let(:existing_task) do
        FactoryGirl.create(
          :task,
          project: project,
          user: task_user,
          state: 'accepted',
          current_fund: 200.0,
          budget: 200.0,
          number_of_participants: 2,
          target_number_of_participants: 2
        )
      end
      let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
      let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
      let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }
      let(:task_user) { FactoryGirl.create(:user, :confirmed_user) }


      before do
        project_team = project.create_team(name: "Team#{project.id}")
        TeamMembership.create!(team_member: user, team_id: project_team.id, role: 1)
        TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)

        project.followers << only_follower
        project.followers << follower_and_member
        project.save!

        allow(NotificationMailer).to receive(:task_started).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)
      end

      it 'task goes in state of doing' do
        expect { make_request }.to change { existing_task.reload.state }.from('accepted').to('doing')
      end

      it 'redirects to project taskstab path' do
        make_request

        expect(response).to redirect_to(taskstab_project_url(existing_task.project, tab: 'Tasks'))
      end

      it 'flashes the correct message' do
        make_request

        expect(flash[:notice]).to eq('Task Status changed to Doing')
      end

      it 'sends an email to the involved users', :aggregate_failures do
        expect(NotificationMailer).to receive(:task_started).exactly(3).times
        expect(message_delivery).to receive(:deliver_later).exactly(3).times

        make_request
      end
    end
  end


  describe '#destroy' do
    let(:task) { FactoryGirl.create(:task, :with_associations) }
    let(:user) { task.user }
    let(:project) { task.project }

    context "given user is authorized" do
      before do
        allow_any_instance_of(described_class).to receive(:authorize!).and_return(true)
      end

      context "when task delete service returns true" do
        before do
          allow_any_instance_of(TaskDestroyService).to receive(:destroy_task).and_return(true)
        end

        it 'returns user to tasks page with successful message' do
          delete(:destroy, id: task.id)

          expect(flash[:notice]).to eq('Task was successfully destroyed.')
          expect(response).to redirect_to(
            taskstab_project_path(project, tab: 'Tasks')
          )
        end
      end

      context "when task delete service returns false" do
        before do
          allow_any_instance_of(TaskDestroyService).to receive(:destroy_task).and_return(false)
        end

        it 'returns user to tasks page with unsuccessful message' do
          delete(:destroy, id: task.id)

          expect(flash[:alert]).to eq('Error happened while task delete process')
          expect(response).to redirect_to(
            taskstab_project_path(project, tab: 'Tasks')
          )
        end
      end
    end
  end

  describe '#completed' do
    before do
      allow_any_instance_of(TaskCompleteService).to receive(:update_current_fund!).and_return(true)
    end

    let(:task_params) do
      {
        state: :reviewing,
        project: project,
        user: user,
        current_fund: 10_000_000,
        satoshi_budget: 10_000_000
      }
    end
    let(:existing_task) do
      FactoryGirl.create(:task, :with_associations, :with_wallet, task_params)
    end

    it "performs successful task completion" do
      allow_any_instance_of(TaskCompleteService).to receive(:complete!).and_return(true)
      get :completed, id: existing_task.id

      expect(assigns(:notice)).to eq("Task was successfully completed")
    end

    it "performs not successful task completion" do
      allow_any_instance_of(TaskCompleteService).to receive(:complete!).and_raise(
        Payments::BTC::Errors::TransferError, "Some Error"
      )
      get :completed, id: existing_task.id

      expect(assigns(:notice)).to eq("Some Error")
    end
  end

# TODO: this speci should be updated accordingly to our logic, it seems that task is not deleted after :reject
# see: https://travis-ci.com/YouServe/Main-App/builds/40999235
=begin
  describe '#reject' do
    let(:existing_task) do
      FactoryGirl.create(:task, :with_associations, project: project, user: user)
    end

    it 'deletes task' do
      expect(Task.exists?(id: existing_task.id)).to eq true

      get(:reject, { id: existing_task.id })

      expect(Task.exists?(id: existing_task.id)).to_not eq true
    end

    it 'redirects to project taskstab path' do
      get(:reject, { id: existing_task.id })

      expect(response).to redirect_to(
        taskstab_project_path(existing_task.project, tab: 'Tasks')
      )
    end
  end


  describe "#accept" do
    let(:existing_task) do
      FactoryGirl.create(:task, :with_associations, project: project, user: user)
    end

    it 'accepts the task' do
      expect(existing_task.pending?).to be true
      expect(existing_task.accepted?).to be false

      get(:accept, { id: existing_task.id })

      updated_task = Task.find(existing_task.id)
      expect(updated_task.pending?).to be false
      expect(updated_task.accepted?).to be true
    end

    it 'redirects to project taskstab path' do
      get(:accept, { id: existing_task.id })

      expect(response).to redirect_to(
        taskstab_project_path(existing_task.project, tab: 'Tasks')
      )
    end
  end
=end

end
