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

  describe 'MediaWiki API actions', vcr: { cassette_name: 'mediawiki' } do
    let(:project) { create(:project, wiki_page_name: 'test') }

    describe '.page_read' do
      subject { project.page_read }

      context 'without username' do
        it 'returns a success result' do
          expect(subject['status']).to eq 'success'
          expect(subject['revision_id']).to eq 72
          expect(subject['non-html']).to eq 'hello'
          expect(subject['html']).to eq "<p>hello\n</p>"
          expect(subject['is_blocked']).to eq 0
        end
      end

      context 'with username' do
        subject { project.page_read('homer') }
        it 'returns a success result' do
          expect(subject['status']).to eq 'success'
          expect(subject['revision_id']).to eq 72
          expect(subject['non-html']).to eq 'hello'
          expect(subject['html']).to eq "<p>hello\n</p>"
          expect(subject['is_blocked']).to eq 0
        end
      end

      context 'unknown page' do
        let(:project) { create(:project, wiki_page_name: 'unknown page') }
        it { expect(subject['status']).to eq 'error' }
      end
    end

    describe '.page_write' do
      let(:user) { create(:user, username: 'homer') }
      subject { project.page_write(user, 'a test') }

      it { is_expected.to eq 200 }
    end

    describe '.get_latest_revision' do
      subject { project.get_latest_revision }

      it { is_expected.to eq 'a test' }
    end

    describe '.get_history' do
      subject { project.get_history }

      it 'returns an array with revisions' do
        expect(subject).not_to be_nil
        expect(subject.count).to eq 5
      end
    end

    describe '.get_revision' do
      subject { project.get_revision(627) }

      it 'returns the specific revision' do
        expect(subject['parent_id']).to eq 586
        expect(subject['author']).to eq 'Homer'
        expect(subject['timestamp']).to eq '1496099755'
        expect(subject['comment']).to eq ''
        expect(subject['diff']).to eq(-3)
        expect(subject['content']).to eq 'a test'
        expect(subject['status']).to eq 'unknown'
      end
    end

    describe '.approve_revision' do
      subject { project.approve_revision(627) }

      it { is_expected.to eq 200 }
    end

    describe '.unapprove_revision' do
      subject { project.unapprove_revision(627) }

      it { is_expected.to eq 200 }
    end

    describe '.unapprove' do
      subject { project.unapprove }

      it { is_expected.to eq 200 }
    end

    describe '.block_user' do
      subject { project.block_user('homer') }

      it { is_expected.to eq 200 }
    end

    describe '.unblock_user' do
      subject { project.unblock_user('homer') }

      it { is_expected.to eq 201 }
    end

    describe '.rename_page' do
      let(:project) { create(:project, wiki_page_name: 'New Test') }
      subject { project.rename_page('homer', 'Test') }

      it { is_expected.to eq 200 }
    end

    describe '.grant_permissions' do
      subject { project.grant_permissions('homer') }

      it { is_expected.to eq 200 }
    end

    describe '.revoke_permissions' do
      subject { project.revoke_permissions('homer') }

      it { is_expected.to eq 200 }
    end

    describe '.archive' do
      subject { project.archive('homer') }

      it { is_expected.to eq 200 }
    end

    describe '.unarchive' do
      subject { project.unarchive('homer') }

      it { is_expected.to eq 200 }
    end
  end
end
