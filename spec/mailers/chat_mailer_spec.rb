require "rails_helper"

RSpec.describe ChatMailer, type: :mailer do
  describe '#invite_receiver' do
    subject(:email) do
      described_class.invite_receiver(requester.id, receiver.id).deliver_now
    end
    let!(:requester) { create(:user, :confirmed_user, first_name: 'Homer', last_name: 'Simpson') }
    let!(:receiver) { create(:user, :confirmed_user) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(receiver.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to(
        eq('[WeServe] Homer Simpson wants to talk with you')
      )
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to(
        include('Homer Simpson have requested to talk with you')
      )
    end
  end
end
