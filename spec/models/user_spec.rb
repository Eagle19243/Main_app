require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    it '#validate_name_unchange' do
      subject = create(:user, name: 'user_name')

      subject.name = 'new_user_name'
      subject.valid?

      expect(subject.errors[:name]).to include /is not allowed to change/
    end
  end

  describe 'user wallet creation' do
    it 'does not assign user wallet on creation' do
      user = create(:user, name: 'user_name')
      user.reload
      expect(user.wallet).to be_nil
    end

    it 'assigns user wallet on creation' do
      user = create(:user, :with_wallet, name: 'user_name')
      user.reload
      expect(user.wallet).to be_present
    end
  end

  describe 'instance methods' do
    subject { create(:user) }

    describe '#is_lead_editor_for?' do
      let(:project) { create(:project) }

      context 'is lead editor of given project' do
        before do
          team = create(:team, project: project)
          create(:team_membership, :lead_editor, team: team, team_member: subject)
        end

        it do
          expect(subject.is_lead_editor_for?(project)).to be_truthy
        end
      end

      context 'is not a team of given project' do
        it do
          expect(subject.is_lead_editor_for?(project)).to be_falsy
        end
      end

      context 'is an coordinator of the given project' do
        before do
          team = create(:team, project: project)
          create(:team_membership, :coordinator, team: team, team_member: subject)
        end

        it do
          expect(subject.is_lead_editor_for?(project)).to be_falsy
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
