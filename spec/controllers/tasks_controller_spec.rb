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
          taskstab_project_path(project, tab: 'tasks')
        )
      end
    end
  end

  describe '#update' do
    let(:existing_task) do
      FactoryGirl.create(:task, :with_associations, :with_wallet, project: project, user: user)
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
      existing_task.wallet.update_attribute(:balance, 100)

      expect {
        patch(:update, id: existing_task.id, task: update_params)
      }.not_to change {
        Task.find(existing_task.id).deadline
      }
    end
  end

  describe '#reviewing' do
    subject(:make_request) { get(:reviewing, { id: existing_task.id }) }

    context 'when the task is eligible to move to under review' do
      let(:existing_task) do
        FactoryGirl.create(
          :task,
          :with_wallet,
          project: project,
          user: user,
          state: 'doing',
          current_fund: 200.0,
          budget: 200.0,
          number_of_participants: 1,
          target_number_of_participants: 1
        )
      end
      let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
      let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
      let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }
      let(:task_user) { FactoryGirl.create(:user, :confirmed_user) }


      before do
        project_team = project.create_team(name: "Team#{project.id}")
        team_membership = TeamMembership.create!(team_member: user, team_id: project_team.id, role: 1)
        TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)
        team_membership.tasks << existing_task
        team_membership.save!

        project.followers << only_follower
        project.followers << follower_and_member
        project.save!

        TaskMember.create(task_id: existing_task.id, team_membership_id: team_membership.id)
        # existing_task.task_members << user
        existing_task.save!

        allow(NotificationMailer).to receive(:under_review_task).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)
        allow_any_instance_of(User).to receive(:can_submit_task?).with(existing_task).and_return(true)
      end

      it 'task goes in state of doing' do
        expect { make_request }.to change { existing_task.reload.state }.from('doing').to('reviewing')
      end

      it 'redirects to project taskstab path' do
        make_request

        expect(response).to redirect_to(taskstab_project_url(existing_task.project, tab: 'tasks'))
      end

      it 'flashes the correct message' do
        make_request

        expect(flash[:notice]).to eq('Task Submitted for Review')
      end

      it 'sends an email to the involved users', :aggregate_failures do
        expect(NotificationMailer).to receive(:under_review_task).exactly(3).times
        expect(message_delivery).to receive(:deliver_later).exactly(3).times

        make_request
      end
    end
  end

  describe '#doing' do
    subject(:make_request) { get(:doing, { id: existing_task.id }) }

    context 'when the task is eligible to move to doing' do
      let(:existing_task) do
        FactoryGirl.create(
          :task,
          :with_wallet,
          project: project,
          user: task_user,
          state: 'accepted',
          current_fund: 200.0,
          budget: 200.0,
          number_of_participants: 1,
          target_number_of_participants: 1
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

        expect(response).to redirect_to(taskstab_project_url(existing_task.project, tab: 'tasks'))
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
            taskstab_project_path(project, tab: 'tasks')
          )
        end
      end

      context "when task delete service returns false" do
        before do
          allow_any_instance_of(TaskDestroyService).to receive(:destroy_task).and_return(false)
        end

        it 'returns user to tasks page with unsuccessful message' do
          delete(:destroy, id: task.id)

          expect(flash[:error]).to eq('Error happened during task delete process')
          expect(response).to redirect_to(
            taskstab_project_path(project, tab: 'tasks')
          )
        end
      end

      context "when task delete service returns general error" do
        before do
          allow_any_instance_of(TaskDestroyService).to receive(:destroy_task) do
            raise Payments::BTC::Errors::GeneralError, "Coinbase API error"
          end
        end

        it 'returns user to tasks page with unsuccessful message' do
          delete(:destroy, id: task.id)

          expect(flash[:error]).to eq('There is a temporary problem connecting to payment service. Please try again later')
          expect(response).to redirect_to(
            taskstab_project_path(project, tab: 'tasks')
          )
        end
      end
    end
  end

  describe '#remove_member' do
    let(:task)            { create(:task, :pending, project: project) }
    let(:team_membership) { create(:team_membership, :task, task: task) }

    context 'reason given' do
      before do
        delete :remove_member, id: task.id, team_membership_id: team_membership.id, reason: 'need new member', format: :json
      end

      it 'removes success' do
        expect(response.status).to eq(200)
      end

      it 'creates an activity' do
        expect(Activity.count).to eq 1
      end
    end

    context 'no reason given' do
      before do
        delete :remove_member, id: task.id, team_membership_id: team_membership.id, format: :json
      end

      it "doesn't remove member" do
        expect(response.status).to eq(422)
      end
    end
  end

  describe '#completed' do
    before do
      allow_any_instance_of(Task).to receive(:update_current_fund!).and_return(true)
      project_team = project.create_team(name: "Team#{project.id}")
      TeamMembership.create!(team_member: user, team_id: project_team.id, role: 1)
      TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)

      project.followers << only_follower
      project.followers << follower_and_member
      project.save!

      allow(NotificationMailer).to receive(:task_completed).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_later)
    end

    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
    let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
    let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }

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

    it "performs not successful task completion" do
      allow_any_instance_of(TaskCompleteService).to receive(:complete!).and_raise(
        Payments::BTC::Errors::GeneralError, "Coinbase API error"
      )
      get :completed, id: existing_task.id

      expect(assigns(:notice)).to eq("There is a temporary problem connecting to payment service. Please try again later")
    end

    it 'sends an email to the involved users', :aggregate_failures do
      allow_any_instance_of(TaskCompleteService).to receive(:complete!).and_return(true)
      expect(NotificationMailer).to receive(:task_completed).exactly(3).times
      expect(message_delivery).to receive(:deliver_later).exactly(3).times

      get :completed, id: existing_task.id
    end
  end

  xdescribe '#reject' do
    subject(:make_request) { get(:reject, { id: existing_task.id }) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    shared_examples :deleted_task do
      it 'deletes task' do
        expect(Task.exists?(id: existing_task.id)).to eq true

        make_request

        expect(Task.exists?(id: existing_task.id)).to_not eq true
      end

      it 'redirects to project taskstab path' do
        make_request

        expect(response).to redirect_to(taskstab_project_url(existing_task.project, tab: 'tasks'))
      end

      it 'flashes the correct message' do
        make_request

        expect(flash[:notice]).to eq("Task #{existing_task.title} has been rejected")
      end
    end

    context 'when the task is in the state of suggested_task' do
      context 'when the task is deleted successful' do
        let(:existing_task) do
          FactoryGirl.create(:task, :with_associations, project: project, user: task_user, state: 'suggested_task')
        end

        let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
        let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
        let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }
        let(:task_user) { FactoryGirl.create(:user, :confirmed_user) }


        before do
          project_team = project.create_team(name: "Team#{project.id}")
          TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)
          project.followers << only_follower
          project.followers << follower_and_member
          project.save!

          allow(NotificationMailer).to receive(:notify_others_for_rejecting_new_task).and_return(message_delivery)
          allow(NotificationMailer).to receive(:notify_user_for_rejecting_new_task).and_return(message_delivery)
          allow(message_delivery).to receive(:deliver_later)
        end

        include_examples :deleted_task

        it 'sends an email to the involved users', :aggregate_failures do
          expect(NotificationMailer).to receive(:notify_others_for_rejecting_new_task).exactly(3).times
          # aggregation of the delivery messages
          expect(message_delivery).to receive(:deliver_later).exactly(4).times

          make_request
        end

        it 'sends an email to the user that owns the task', :aggregate_failures do
          expect(NotificationMailer).to receive(:notify_user_for_rejecting_new_task).exactly(1).times
          # aggregation of the delivery messages
          expect(message_delivery).to receive(:deliver_later).exactly(4).times

          make_request
        end
      end
    end

    context 'when the task is NOT in the state of suggested_task' do
      context 'when the task is deleted successful' do
        let(:existing_task) do
          FactoryGirl.create(:task, :with_associations, project: project, user: task_user, state: 'accepted')
        end
        let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
        let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
        let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }
        let(:task_user) { FactoryGirl.create(:user, :confirmed_user) }


        before do
          project_team = project.create_team(name: "Team#{project.id}")
          TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)
          project.followers << only_follower
          project.followers << follower_and_member
          project.save!

          allow(NotificationMailer).to receive(:task_deleted).and_return(message_delivery)
          allow(message_delivery).to receive(:deliver_later)
        end

        include_examples :deleted_task

        it 'sends an email to the involved users', :aggregate_failures do
          expect(NotificationMailer).to receive(:task_deleted).exactly(3).times
          expect(message_delivery).to receive(:deliver_later).exactly(3).times

          make_request
        end
      end
    end
  end


  describe '#accept' do
    subject(:make_request) { get(:accept, { id: existing_task.id }) }

    context 'when the task is accepted successful' do
      let(:existing_task) do
        FactoryGirl.create(:task, :with_associations, project: project, user: task_user, state: 'pending')
      end
      let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
      let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
      let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }
      let(:task_user) { FactoryGirl.create(:user, :confirmed_user) }


      before do
        project_team = project.create_team(name: "Team#{project.id}")
        TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)

        project.followers << only_follower
        project.followers << follower_and_member
        project.save!

        allow(NotificationMailer).to receive(:accept_new_task).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)
      end

      it 'accepts the task' do
        expect(existing_task.pending?).to be true
        expect(existing_task.accepted?).to be false

        make_request

        updated_task = Task.find(existing_task.id)
        expect(updated_task.pending?).to be false
        expect(updated_task.accepted?).to be true
      end

      it 'redirects to project taskstab path' do
        make_request

        expect(response).to redirect_to(taskstab_project_url(existing_task.project, tab: 'tasks'))
      end

      it 'flashes the correct message' do
        make_request

        expect(flash[:notice]).to eq('Task accepted')
      end

      it 'sends an email to the involved users', :aggregate_failures do
        expect(NotificationMailer).to receive(:accept_new_task).exactly(4).times
        expect(message_delivery).to receive(:deliver_later).exactly(4).times

        make_request
      end
    end
  end
end
