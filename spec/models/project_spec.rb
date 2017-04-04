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
end
