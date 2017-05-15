require 'rails_helper'

RSpec.describe RequestMailer, type: :mailer do
  include ActionView::Helpers::UrlHelper

  describe '#apply_to_get_involved_in_project' do
    subject(:email) { described_class.apply_to_get_involved_in_project(applicant: applicant, project: project, request_type: request_type).deliver_now }
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:applicant) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:request_type) { nil }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(leader.email)
    end

    context 'when request_type is coordinator', aggregate_failures: true do
      let(:request_type) { 'Coordinator' }

      it 'has the correct subject' do
        expect(email.subject).to eq(I18n.t('request_mailer.apply_to_get_involved_in_project.subject', request_type: request_type))
      end

      it 'has the correct body' do
        expect(CGI.unescapeHTML(email.body.to_s)).to include("#{applicant.display_name} has submitted an application as #{request_type} for the project #{link_to project.title, project_url(project.id)}.")
      end

    end

    context 'when request_type is Lead Editor', aggregate_failures: true do
      let(:request_type) { 'Lead Editor' }

      it 'has the correct subject' do
        expect(email.subject).to eq(I18n.t('request_mailer.apply_to_get_involved_in_project.subject', request_type: request_type))
      end

      it 'has the correct body' do
        expect(CGI.unescapeHTML(email.body.to_s)).to include("#{applicant.display_name} has submitted an application as #{request_type} for the project #{link_to project.title, project_url(project.id)}")
      end
    end
  end

  describe '#positive_response_in_project_involvement' do
    subject(:email) { described_class.positive_response_in_project_involvement(apply_request: apply_request).deliver_now }
    let(:user_in_request) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:apply_request) { FactoryGirl.create(:lead_editor_request, user: user_in_request, project: project) }
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:request_type) { apply_request.request_type.try(:tr, '_', ' ') }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(user_in_request.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('request_mailer.positive_response_in_project_involvement.subject', request_type: request_type))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include("Your application to become a #{request_type} for project #{link_to project.title, project_url(project.id)} was accepted by #{project.leader.display_name}")
    end
  end

  describe '#negative_response_in_project_involvement' do
    subject(:email) { described_class.negative_response_in_project_involvement(apply_request: apply_request).deliver_now }
    let(:user_in_request) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:apply_request) { FactoryGirl.create(:lead_editor_request, user: user_in_request, project: project) }
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:request_type) { apply_request.request_type.try(:tr, '_', ' ') }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(user_in_request.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('request_mailer.negative_response_in_project_involvement.subject', request_type: request_type))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include("Sorry, but your application to become a #{request_type} for project #{link_to project.title, project_url(project.id)} was declined by #{project.leader.display_name}")
    end
  end

  describe '#to_do_task' do
    subject(:email) { described_class.to_do_task(requester: user_in_request, task: task).deliver_now }
    let(:user_in_request) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }

    let(:task) { FactoryGirl.create(:task, project: project) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(leader.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('request_mailer.to_do_task.subject'))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include("#{user_in_request.display_name} applied for the task #{task.title} and need to be reviewed.")
    end
  end

  describe '#accept_to_do_task' do
    subject(:email) { described_class.accept_to_do_task(do_request: do_request).deliver_now }
    let(:user_in_request) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:do_request) { FactoryGirl.create(:do_request, user: user_in_request, project: project, task: task) }
    let(:task) { FactoryGirl.create(:task, project: project) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(user_in_request.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('request_mailer.accept_to_do_task.subject'))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include("Your application for task #{task.title} in project #{link_to task.project.title, project_url(task.project.id)} was approved.")
    end
  end

  describe '#reject_to_do_task' do
    subject(:email) { described_class.reject_to_do_task(do_request: do_request).deliver_now }
    let(:user_in_request) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:project) { FactoryGirl.create(:project, user: leader) }
    let(:leader) { FactoryGirl.create(:user, email: Faker::Internet.email, confirmed_at: Time.now) }
    let(:do_request) { FactoryGirl.create(:do_request, user: user_in_request, project: project, task: task) }
    let(:task) { FactoryGirl.create(:task, project: project) }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(user_in_request.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('request_mailer.reject_to_do_task.subject'))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include("Your application for task #{task.title} in project #{link_to task.project.title, project_url(task.project.id)} was rejected.")
    end
  end
end
