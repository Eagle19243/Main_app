require 'rails_helper'

RSpec.describe TasksController, vcr: { cassette_name: 'bitgo' } do
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
      FactoryGirl.create(:task_with_associations, project: project, user: user)
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

  describe '#reject' do
    let(:existing_task) do
      FactoryGirl.create(:task_with_associations, project: project, user: user)
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
      FactoryGirl.create(:task_with_associations, project: project, user: user)
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
end
