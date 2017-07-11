require 'rails_helper'

feature 'Logo working correctly', type: :feature, js: true do

  before do
    @user = FactoryGirl.create(:user)
    @user.confirmed_at = Time.now
    @user.save
  end

  let(:email) { @user.email }
  let(:password) { @user.password }

  scenario 'Website is working or not' do
    visit '/'
    page.status_code == '200'
  end

  scenario 'Going to random page on site' do
    visit root_path
    find('.header-link._active-project').click

    expect(page).to have_current_path(projects_path)
  end

  scenario 'Must be redirected to landing page when clicking logo on site' do
    visit projects_path

    click_pseudo_link 'WeServe'
    expect(page).to have_current_path(root_path)
  end

  scenario 'logging in with email' do
    visit root_path
    click_pseudo_link 'Login'
    modal = find('div#registerModal', visible: true)
    sign_up_form = modal.find('._sign-in#sign_in_show')

    sign_up_form.fill_in 'user_email', with: email
    sign_up_form.fill_in 'user_password', with: password
    sign_up_form.click_button 'Sign in'

    expect(page).to have_current_path(root_path)
  end

  scenario 'User logged in goes to random page on site' do
    visit projects_path

    expect(page).to have_link('Explore projects')
    expect(page).to have_text('Browse Projects')
  end

  scenario 'Must be redirected to home page when clicking logo on site' do
    visit projects_path

    click_pseudo_link 'WeServe'
    expect(page).to have_current_path(root_path)
  end
end
