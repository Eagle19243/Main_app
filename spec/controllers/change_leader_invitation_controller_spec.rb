require 'rails_helper'

describe ChangeLeaderInvitationController, type: :request do
  describe 'GET /change_leader_invitation/:id/accept' do
    subject(:make_request) { get("/change_leader_invitation/#{change_leader_invitation.id}/accept") }
    let(:project) { FactoryGirl.create(:project, user: current_leader) }
    let(:current_leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:change_leader_invitation) { FactoryGirl.create(:change_leader_invitation, new_leader: new_leader.email, project: project) }
    let(:new_leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }

    before do
      login_as(new_leader, scope: :user, run_callbacks: false)

      # ensure the current_leader has a team membership
      project_team = project.create_team(name: "Team#{project.id}")
      TeamMembership.create!(team_member: current_leader, team_id: project_team.id, role: 1)
      # make the new leader as a team member before electing him as the new leader
      TeamMembership.create!(team_member: new_leader, team_id: project_team.id, role: 0)

      allow(InvitationMailer).to receive(:notify_previous_leader_for_new_leader).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_later)
    end


    context 'when update is successful' do
      let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

      it 'displays the correct notice message and redirects to my projects', aggregate_failures: true do
        make_request

        expect(flash[:notice]).to eq("Congratulations! You are project leader of #{change_leader_invitation.project.title}!")
        expect(response).to redirect_to(:my_projects)
      end

      it 'sends an email to be delivered later', aggregate_failures: true do
        expect(InvitationMailer).to receive(:notify_previous_leader_for_new_leader).with(project: project, previous_leader: current_leader)
        expect(message_delivery).to receive(:deliver_later)

        make_request
      end
    end
  end
end
