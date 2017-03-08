require 'rails_helper'

RSpec.describe Project, :type => :model, vcr: { cassette_name: 'bitgo' } do

  describe "short_description validation" do
    before {
      @project = FactoryGirl.create(:project)
    }

    context 'errors' do
      it 'validates min length - 2 chars' do
        @project.short_description = 'ab'
        expect { @project.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Short description Has invalid length. Min length is 3, max length is 250')
      end

      it 'validates min length - 0 chars' do
        @project.short_description = ''
        expect { @project.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Short description can\'t be blank, Short description Has invalid length. Min length is 3, max length is 250')
      end

      it 'validates max length' do
        @project.short_description = Faker::Lorem.sentence(251)
        expect { @project.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Short description Has invalid length. Min length is 3, max length is 250')
      end

      it 'validates max length - too many chars' do
        @project.short_description = Faker::Lorem.sentence(400)
        expect { @project.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Short description Has invalid length. Min length is 3, max length is 250')
      end
    end

    context 'success' do
      it 'validates allowed length' do
        @project.short_description = 'abcd'
        expect(@project.save!).to be true
      end

      it 'validates allowed length - maximum 250' do
        @project.short_description = Faker::Lorem.characters(250)
        expect(@project.save!).to be true
      end
    end
  end

end
