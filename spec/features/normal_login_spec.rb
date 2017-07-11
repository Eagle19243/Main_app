require 'rails_helper'

feature 'Normal login', js: true do
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
    form = modal.find('._sign-in#sign_in_show')

    form.fill_in 'user_email', with: email
    form.fill_in 'user_password', with: password
    form.click_button 'Sign in'

    expect(page).to have_current_path(home_index_path, only_path: true)
  end
end
