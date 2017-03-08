require 'rails_helper'

feature 'Notifications', js: true, vcr: { cassette_name: 'bitgo' } do
  context 'load older notifications' do
    let(:user)          { create(:user, :confirmed_user) }
    let(:another_user)  { create(:user, :confirmed_user) }
    let(:project)       { create(:project, user: user) }

    before do
      create_list(:task, 2, :suggested, user: another_user, project: project)

      login_as(user, scope: :user, run_callbacks: false)
      NotificationsController::PER_LOAD_COUNT = 2
      visit notifications_path
    end

    scenario 'loads the notification of id 111' do
      expect(page).not_to have_content('You have created project')

      find('.load-older-notifications-link a').click
      wait_for_ajax

      expect(page).to have_content('You have created project')
    end
  end
end
