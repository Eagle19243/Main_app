require 'rails_helper'

feature 'Main page popups' do
  scenario 'when anonymous user visits', js: true do
    visit root_path

    click_pseudo_link 'Register'

    modal = find('div#registerModal', visible: true)

    expect(modal).to be_visible

    expect(modal).to have_link 'Sign In with Google'
    expect(modal).to have_link 'Sign In with Twitter'
    expect(modal).to have_link 'Sign In with Facebook'

    expect(modal).to have_field 'user_username'
    expect(modal).to have_field 'user_email'
    expect(modal).to have_field 'user_password'
    expect(modal).to have_field 'user_password_confirmation'
    expect(modal).to have_button 'Sign up'
  end

  scenario 'Projects page is working for anonymous user', js: true do
    visit '/'

    find('.header-link._active-project').click

    expect(page).to have_current_path(projects_path, only_path: true)
  end
end
