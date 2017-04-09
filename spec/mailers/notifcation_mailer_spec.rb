require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe '#revision_approved' do
    subject(:email) { described_class.revision_approved(approver: project.leader, project: project, receiver: user).deliver_now }
    let(:user) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(user.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.notification.revision_approved.subject'))
    end

    it 'has the correct body' do
      expect(email.body).to include("#{leader.name} changed the approved version of the project #{link_to project.title, project_url(project.id)}.")
    end
  end

  describe '#task_started' do
    subject(:email) { described_class.task_started(acting_user: user, task: task, receiver: leader).deliver_now }
    let(:user) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, project: project) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(leader.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.notification.task_started.subject'))
    end

    it 'has the correct body' do
      expect(email.body).to include("#{user.name} started task #{task.title} of project #{link_to(task.project.title, project_url(task.project.id))}.")
    end
  end
end
