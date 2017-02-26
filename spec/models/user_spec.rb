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
end
