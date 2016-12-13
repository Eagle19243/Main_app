require 'rails_helper'

feature 'Registration' do
  before do
    visit '/'
    click_pseudo_link 'Register'
  end

  let(:email) { 'metallurgist@hauptstimme.com' }
  let(:last_delivery) { ActionMailer::Base.deliveries.last }

  scenario 'when user registers using normal method', js: true, vcr: { cassette_name: 'bitgo' } do
    modal = find('div#registerModal', visible: true)

    modal.fill_in 'name', with: 'The Metallurgist'
    modal.fill_in 'new_email', with: email
    modal.fill_in 'new_password', with: 'surripere'
    modal.fill_in 'password_confirmation', with: 'surripere'
    modal.click_button 'Sign up'

    expect(page).to have_current_path(home_index_path)
    expect(page).to have_text 'A message with a confirmation link has been sent'
    expect(last_delivery.body.raw_source).to include "Welcome #{email}"
    expect(last_delivery.body.raw_source).to include "You can confirm your account email"
  end
end
