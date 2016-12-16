require 'rails_helper'

feature 'Normal login', js: true, vcr: { cassette_name: 'bitgo' } do
  before do
    @user = FactoryGirl.create(:user)
    @user.confirmed_at = Time.now
    @user.save
  end

  let(:email) { @user.email }
  let(:password) { @user.password }

  scenario 'when user log in using normal method' do
    visit root_path
    click_pseudo_link 'Login'
    modal = find('div#registerModal', visible: true)

    modal.fill_in 'email', with: email
    modal.fill_in 'password', with: password
    modal.click_button 'Sign in'

    expect(page).to have_current_path(home_index_path)
  end
end
