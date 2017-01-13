require 'rails_helper'

feature 'Register popup displaying correctly', type: :feature, js: true do
  scenario 'Website is working or not' do
    visit '/'
    page.status_code == '200'
  end

  scenario 'Anonymous user should see register modal on home page' do
    visit root_path
    expect(page).to have_text('Turn your audience into a task force')

    click_pseudo_link 'Register'
    
    modal = find('div#registerModal', visible: true)
    expect(modal).to be_visible

    expect(modal).to have_link 'Sign In with Google'
    expect(modal).to have_link 'Sign In with Twitter'
    expect(modal).to have_link 'Sign In with Facebook'

    expect(modal).to have_field 'name'
    expect(modal).to have_field 'new_email'
    expect(modal).to have_field 'new_password'
    expect(modal).to have_field 'password_confirmation'
    expect(modal).to have_button 'Sign up'
  end
end