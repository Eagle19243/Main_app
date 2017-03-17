require 'rails_helper'

RSpec.describe User, type: :model, vcr: { cassette_name: 'bitgo' } do
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

      context 'is an executor of the given project' do
        before do
          team = create(:team, project: project)
          create(:team_membership, :executor, team: team, team_member: subject)
        end

        it do
          expect(subject.is_lead_editor_for?(project)).to be_falsy
        end
      end
    end
  end
end
