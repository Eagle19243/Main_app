require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username) }

    it '#validate_username_unchange' do
      subject = create(:user, username: 'user_name')

      subject.username = 'new_user_name'
      subject.valid?

      expect(subject.errors[:username]).to include /is not allowed to change/
    end
  end

  describe 'check if user is teammate with (for purposes of contact info)' do
    let(:project) { create(:project) }
    let(:first_user) { create(:user) }

    it 'another user on the same project - yes' do
      second_user = create(:user)
      TeamService.add_team_member(project.team,first_user,"teammate")
      TeamService.add_team_member(project.team,second_user,"teammate")
      expect(first_user.is_teammate_with?(second_user)).to eq(true)
      expect(second_user.is_teammate_with?(first_user)).to eq(true)
    end

    it 'himself (even though he isn\'t on any projects) - yes' do
      expect(first_user.is_teammate_with?(first_user)).to eq(true)
    end

    it 'a user that isn\'t on any projects - no' do
      second_user = create(:user)
      TeamService.add_team_member(project.team,first_user,"teammate")
      expect(first_user.is_teammate_with?(second_user)).to eq(false)
      expect(second_user.is_teammate_with?(first_user)).to eq(false)
    end

    it 'a user that is on a different project - no' do
      second_user = create(:user)
      second_project = create(:project)
      TeamService.add_team_member(project.team,first_user,"teammate")
      TeamService.add_team_member(second_project.team,second_user,"teammate")
      expect(first_user.is_teammate_with?(second_user)).to eq(false)
      expect(second_user.is_teammate_with?(first_user)).to eq(false)
    end

    it 'the leader of the project - yes' do
      second_user = project.leader
      TeamService.add_team_member(project.team,first_user,"teammate")
      expect(first_user.is_teammate_with?(second_user)).to eq(true)
      expect(second_user.is_teammate_with?(first_user)).to eq(true)
    end
  end

  describe 'user wallet creation' do
    it 'does not assign user wallet on creation' do
      user = create(:user, username: 'user_name')
      user.reload
      expect(user.wallet).to be_nil
    end

    it 'assigns user wallet on creation' do
      user = create(:user, :with_wallet, username: 'user_name')
      user.reload
      expect(user.wallet).to be_present
    end
  end

  describe 'instance methods' do
    subject { create(:user) }

    context 'when user is an owner of the project' do
      let(:project) { create(:project, user: subject) }

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be true
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be true
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be false
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be true
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be false
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be true
        end
      end
    end

    context 'when user is a pending admin in the project' do
      let(:project) { create(:project) }

      before do
        admin = project.proj_admins.build(user_id: subject.id)
        admin.save
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be false
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be false
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be false
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be false
        end
      end
    end

    context 'when user is a accepted admin in the project' do
      let(:project) { create(:project) }

      before do
        admin = project.proj_admins.build(user_id: subject.id)
        admin.save
        admin.accept!
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be true
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be false
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be false
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be false
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be true
        end
      end
    end

    context 'when user is a rejected admin in the project' do
      let(:project) { create(:project) }

      before do
        admin = project.proj_admins.build(user_id: subject.id)
        admin.save
        admin.reject!
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be false
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be false
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be false
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be false
        end
      end
    end

    context 'when user is a coordinator in the project' do
      let(:project) { create(:project) }

      before do
        team = create(:team, project: project)
        create(:team_membership, :coordinator, team: team, team_member: subject)
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be true
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be true
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be false
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be true
        end
      end
    end

    context 'when user is a lead editor in the project' do
      let(:project) { create(:project) }

      before do
        team = create(:team, project: project)
        create(:team_membership, :lead_editor, team: team, team_member: subject)
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be false
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be false
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be true
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be true
        end
      end
    end

    context 'when user is a teammate in the project' do
      let(:project) { create(:project) }

      before do
        team = create(:team, project: project)
        create(:team_membership, :teammate, team: team, team_member: subject)
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be false
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be false
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be false
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be true
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be true
        end
      end
    end

    context 'when user was a lead_editor and then also became coordinator in the project' do
      let(:project) { create(:project) }

      before do
        team = create(:team, project: project)
        create(:team_membership, :lead_editor, team: team, team_member: subject)
        create(:team_membership, :coordinator, team: team, team_member: subject)
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be true
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be true
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be true
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be true
        end
      end
    end

    context 'when user was a coordinator and then also became a lead_editor in the project' do
      let(:project) { create(:project) }

      before do
        team = create(:team, project: project)
        create(:team_membership, :coordinator, team: team, team_member: subject)
        create(:team_membership, :lead_editor, team: team, team_member: subject)
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be true
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be true
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be true
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be true
        end
      end
    end

    context 'when user is a lead_editor, teammate and coordinator in the project' do
      let(:project) { create(:project) }

      before do
        team = create(:team, project: project)
        create(:team_membership, :coordinator, team: team, team_member: subject)
        create(:team_membership, :teammate, team: team, team_member: subject)
        create(:team_membership, :lead_editor, team: team, team_member: subject)
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be true
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be true
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be true
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be true
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be true
        end
      end
    end

    context 'when user is nobody in the project' do
      let(:project) { create(:project) }

      before do
        create(:team, project: project)
      end

      describe '#is_admin_for?' do
        it do
          expect(subject.is_admin_for?(project)).to be false
        end
      end

      describe '#is_project_leader?' do
        it do
          expect(subject.is_project_leader?(project)).to be false
        end
      end

      describe '#is_coordinator_for?' do
        it do
          expect(subject.is_coordinator_for?(project)).to be false
        end
      end

      describe '#is_project_leader_or_coordinator?' do
        it do
          expect(subject.is_project_leader_or_coordinator?(project)).to be false
        end
      end

      describe '#is_lead_editor_for?' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be false
        end
      end

      describe '#is_teammate_for?' do
        it do
          expect(subject.is_teammate_for?(project)).to be false
        end
      end

      describe '#is_project_team_member?' do
        it do
          expect(subject.is_project_team_member?(project)).to be false
        end
      end
    end

    describe '#current_wallet_balance' do
      context "when user hasn't assigned wallet" do
        it "returns 0 as balance" do
          expect(subject.current_wallet_balance).to eq(0.0)
        end
      end

      context "when user has assigned wallet" do
        let(:subject) { create(:user, :with_wallet) }

        before do
          allow(subject.wallet).to receive(:balance).and_return(50.0)
        end

        it "returns wallet balance" do
          expect(subject.current_wallet_balance).to eq(50.0)
        end
      end
    end
  end
end
