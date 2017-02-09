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

    it 'redirects to card_payment_project_url' do
      make_request
      expect(response).to redirect_to(task_path(@task.id))
    end
  end
end
