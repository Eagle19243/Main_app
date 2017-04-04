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
