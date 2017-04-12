require 'rails_helper'

RSpec.describe PaymentMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe '#fully_funded_task' do
    subject(:email) { described_class.fully_funded_task(task: task, receiver: leader).deliver_now }
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, project: project) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(leader.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.payment.fully_funded_task.subject'))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include(" Task #{task.title} of project #{link_to task.project.title, project_url(task.project.id)} was fully funded")
    end
  end

  describe '#fund_task' do
    subject(:email) { described_class.fund_task(payer: payer, task: task, receiver: leader, amount: amount).deliver_now }
    let(:payer) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:amount) { { bitcoin: 1.12, usd: 1146.24 } }
    let(:task) { FactoryGirl.create(:task, project: project) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(leader.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.payment.fund_task.subject'))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include("#{payer.name} has donated #{amount[:bitcoin]} BTC/ $ #{amount[:usd]} to task #{task.title}")
    end
  end
end
