require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe '#comment' do
    subject(:email) { described_class.comment(task_comment: task_comment, receiver: leader).deliver_now }
    let(:user) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:task) { FactoryGirl.create(:task, project: project) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task_comment) { FactoryGirl.create(:task_comment, task: task, user: user) }


    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(leader.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.notification.comment.subject'))
    end

    it 'has the correct body' do
      expect(email.body).to include("#{task_comment.user.name} added a comment to task #{link_to(task.title, taskstab_project_url(project.id, tab: 'Tasks', taskId: task.id))}.")
    end
  end

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

  describe '#accept_new_task' do
    subject(:email) { described_class.accept_new_task(task: task, receiver: user).deliver_now }
    let(:user) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, user: user, project: project, state: 'pending') }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(user.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.notification.accept_new_task.subject'))
    end

    it 'has the correct body' do
      expect(email.body).to include("Task #{task.title} for project #{link_to task.project.title, project_url(task.project.id)} was approved.")
    end
  end


  describe '#notify_user_for_rejecting_new_task' do
    subject(:email) { described_class.notify_user_for_rejecting_new_task(task_title: task.title, project: project, receiver: user).deliver_now }
    let(:user) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, user: user, project: project, state: 'pending') }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(user.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.notification.notify_user_for_rejecting_new_task.subject'))
    end

    it 'has the correct body' do
      expect(email.body).to include("Your task #{task.title} for project #{link_to task.project.title, project_url(task.project.id)} has not been accepted by the project leader.")
    end
  end

  describe '#notify_others_for_rejecting_new_task' do
    subject(:email) { described_class.notify_others_for_rejecting_new_task(task_title: task.title, project: project, receiver: user).deliver_now }
    let(:user) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, user: user, project: project, state: 'pending') }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(user.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.notification.notify_others_for_rejecting_new_task.subject'))
    end

    it 'has the correct body' do
      expect(email.body).to include("Task #{task.title} for project #{link_to task.project.title, project_url(task.project.id)} has not been accepted by the project leader.")
    end
  end

  describe '#task_deleted' do
    subject(:email) { described_class.task_deleted(task_title: task.title, project: project, receiver: leader, admin: admin).deliver_now }
    let(:user) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:base_project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }
    let(:task) { FactoryGirl.create(:task, user: user, project: project, state: 'pending') }
    let(:admin) { FactoryGirl.create(:user, email: Faker::Internet.email, name: Faker::Name.name, confirmed_at: Time.now) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(leader.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('mailers.notification.task_deleted.subject'))
    end

    it 'has the correct body' do
      expect(email.body).to include("Task #{task.title} for project #{link_to task.project.title, project_url(task.project.id)} was deleted by #{admin.name}")
    end
  end
end
