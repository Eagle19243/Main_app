require 'rails_helper'

describe DoRequestsController, type: :request do
  describe 'POST /do_requests' do
    subject(:make_request) { post("/do_requests", params) }
    let(:params) { { do_request: { task_id: task.id, application: 'Reason to do the task', free: false } } }
    let(:user_in_request) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, project: project) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before { login_as(user_in_request, scope: :user, run_callbacks: false) }

    context 'successful creation of request' do
      before do
        allow(RequestMailer).to receive(:to_do_task).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)
      end

      it 'triggers an email to be delivered later', aggregate_failures: true do
        expect(message_delivery).to receive(:deliver_later)
        expect(RequestMailer)
          .to receive(:to_do_task).with(requester: user_in_request, task: task)

        make_request
      end

      it 'redirects to the project with the correct notice message', aggregate_failures: true do
          make_request

          expect(flash[:notice]).to eq('Request sent to Project Admin')
          expect(response).to redirect_to(task)
        end
    end
  end

  describe 'GET /do_requests/:id/accept' do
    subject(:make_request) { get("/do_requests/#{do_request.id}/accept") }
    let(:params) { { do_request: { task_id: task.id, application: 'Reason to do the task', free: false } } }
    #let(:user_in_request) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, project: project) }
    let(:do_request) { FactoryGirl.create(:do_request, task: task, project: task.project) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before { login_as(leader, scope: :user, run_callbacks: false) }

    context 'successful creation of request' do
      before do
        allow(RequestMailer).to receive(:accept_to_do_task).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)
      end

      it 'triggers an email to be delivered later', aggregate_failures: true do
        expect(message_delivery).to receive(:deliver_later)
        expect(RequestMailer).to receive(:accept_to_do_task).with(do_request: do_request)

        make_request
      end

      it 'redirects to the project with the correct notice message', aggregate_failures: true do
        make_request

        expect(flash[:notice]).to eq('Task has been assigned')
        expect(response).to redirect_to(taskstab_project_path(do_request.project, tab: 'requests'))
      end
    end
  end

  describe 'GET /do_requests/:id/reject' do
    subject(:make_request) { get("/do_requests/#{do_request.id}/reject") }
    let(:params) { { do_request: { task_id: task.id, application: 'Reason to do the task', free: false } } }
    #let(:user_in_request) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, project: project) }
    let(:do_request) { FactoryGirl.create(:do_request, task: task, project: task.project) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before { login_as(leader, scope: :user, run_callbacks: false) }

    context 'successful creation of request' do
      before do
        allow(RequestMailer).to receive(:reject_to_do_task).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)
      end

      it 'triggers an email to be delivered later', aggregate_failures: true do
        expect(message_delivery).to receive(:deliver_later)
        expect(RequestMailer).to receive(:reject_to_do_task).with(do_request: do_request)

        make_request
      end

      it 'redirects to the project with the correct notice message', aggregate_failures: true do
        make_request

        expect(flash[:notice]).to eq('Request rejected')
        expect(response).to redirect_to(taskstab_project_path(do_request.project, tab: 'requests'))
      end
    end
  end
end
