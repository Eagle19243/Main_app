require 'rails_helper'

RSpec.describe TasksController, vcr: { cassette_name: 'bitgo' } do

  describe '#create' do
    before {
      user = FactoryGirl.create(:user, :confirmed_user)
      user.admin!
      @project = FactoryGirl.create(:project, user: user)
      sign_in(user)
    }
    subject(:make_request) { post(:create, task: { title: 'title', budget: 1, target_number_of_participants: 1, condition_of_execution: 'condition', deadline: Time.now, project_id: @project.id }) }

    context 'correct redirect' do
      it 'redirects to card_payment_project_url' do
        make_request
        expect(response).to redirect_to(taskstab_project_path(@project, tab: 'Tasks'))
      end
    end
  end

  describe '#reject' do
    before {
      user = FactoryGirl.create(:user, :confirmed_user)
      user.admin!
      @project = FactoryGirl.create(:project, user: user)
      @task = FactoryGirl.create(:task_with_associations, project: @project, user: user)
      sign_in(user)
    }

    subject(:make_request) { get(:reject, { id: @task.id }) }

    it 'deletes task' do
      expect(Task.exists?(id: @task.id)).to eq true
      make_request
      expect(Task.exists?(id: @task.id)).to_not eq true
    end

    it 'redirects to project taskstab path' do
      make_request
      expect(response).to redirect_to(taskstab_project_path(@task.project, tab: 'Tasks'))
    end
  end

  describe "#accept" do
    before {
      user = FactoryGirl.create(:user, :confirmed_user)
      user.admin!
      @project = FactoryGirl.create(:project, user: user)
      @task = FactoryGirl.create(:task_with_associations, project: @project, user: user)
      sign_in(user)
    }

    it 'accepts the task' do
      expect(@task.pending?).to be true
      expect(@task.accepted?).to be false

      get(:accept, { id: @task.id })

      updated_task = Task.find(@task.id)
      expect(updated_task.pending?).to be false
      expect(updated_task.accepted?).to be true
    end

    it 'redirects to project taskstab path' do
      get(:accept, { id: @task.id })
      expect(response).to redirect_to(taskstab_project_path(@task.project, tab: 'Tasks'))
    end
  end
end
