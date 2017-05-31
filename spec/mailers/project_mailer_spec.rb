require 'rails_helper'

RSpec.describe ProjectMailer, type: :mailer do
  let(:user) { FactoryGirl.create(:user) }
  let(:receiver) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }

  describe '#project_text_edited_by_leader' do
    subject(:email) { described_class.project_text_edited_by_leader(editor_id: user.id, project_id: project.id, receiver_id: receiver.id).deliver_now }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(receiver.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('project_mailer.project_text_edited_by_leader.subject'))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include(I18n.t('project_mailer.project_text_edited_by_leader.body_html', 
        project_title: project.title, receiver_display_name: receiver.display_name, 
        editor_display_name: user.display_name).html_safe )
    end
  end

  describe '#project_text_submitted_for_approval' do
    subject(:email) { described_class.project_text_submitted_for_approval(editor_id: user.id, project_id: project.id, receiver_id: receiver.id).deliver_now }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(receiver.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('project_mailer.project_text_submitted_for_approval.subject'))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include(I18n.t('project_mailer.project_text_submitted_for_approval.body_html', 
        project_title: project.title, receiver_display_name: receiver.display_name, 
        editor_display_name: user.display_name, sub_page: "sub_page").html_safe )
    end
  end

  describe '#project_text_edited' do
    subject(:email) { described_class.project_text_edited(editor_id: user.id, project_id: project.id, receiver_id: receiver.id).deliver_now }

    it 'sends an email' do
      expect { email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'has the correct To sender e-mail' do
      expect(email.to.first).to eq(receiver.email)
    end

    it 'has the correct subject' do
      expect(email.subject).to eq(I18n.t('project_mailer.project_text_edited.subject'))
    end

    it 'has the correct body' do
      expect(CGI.unescapeHTML(email.body.to_s)).to include(I18n.t('project_mailer.project_text_edited.body_html', 
        project_title: project.title, receiver_display_name: receiver.display_name, 
        editor_display_name: user.display_name, sub_page: "sub_page").html_safe )
    end
  end

end
