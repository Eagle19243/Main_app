require 'rails_helper'

RSpec.describe Project, type: :model do
  # Association
  it { is_expected.to have_one(:team) }
  it { is_expected.to have_many(:team_members).through(:team) }
  it { is_expected.to have_many(:team_memberships).through(:team) }

  describe 'short_description validation' do
    let(:project) { create(:project) }

    context 'errors' do
      it 'validates min length - 2 chars' do
        project.short_description = 'ab'
        expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Short description Has invalid length. Min length is 3, max length is 250')
      end

      it 'validates min length - 0 chars' do
        project.short_description = ''
        expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Short description can\'t be blank, Short description Has invalid length. Min length is 3, max length is 250')
      end

      it 'validates max length' do
        project.short_description = Faker::Lorem.sentence(251)
        expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Short description Has invalid length. Min length is 3, max length is 250')
      end

      it 'validates max length - too many chars' do
        project.short_description = Faker::Lorem.sentence(400)
        expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Short description Has invalid length. Min length is 3, max length is 250')
      end
    end

    context 'success' do
      it 'validates allowed length' do
        project.short_description = 'abcd'
        expect(project.save!).to be true
      end

      it 'validates allowed length - maximum 250' do
        project.short_description = Faker::Lorem.characters(250)
        expect(project.save!).to be true
      end
    end
  end

  describe '#interested_users' do
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
    let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }
    let(:leader) { FactoryGirl.create(:user, :confirmed_user) }

    before do
      project_team = project.create_team(name: "Team#{project.id}")
      TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)

      project.followers << only_follower
      project.followers << follower_and_member
      project.save!
    end

    it 'returns the the interested users only once' do
      expect(project.reload.interested_users).to contain_exactly(only_follower, follower_and_member, leader)
    end
  end
end
