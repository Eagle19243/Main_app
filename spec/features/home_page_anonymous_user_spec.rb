require 'rails_helper'

feature 'Home page is working for anonymous user', type: :feature, js: true do
  scenario 'Website is working or not' do
    visit '/'
    page.status_code == '200'
  end

  scenario 'Anonymous user visits home page' do
    visit root_path
    expect(page).to have_text('Turn your audience into a task force')
    expect(page).to have_text('Login')
    expect(page).to have_text('Register')
    expect(page).to have_text('Keep control on collaboration at any step')
    expect(page).to have_text('Create Your Prototype')
    expect(page).to have_text('Serve as a Leader')
    expect(page).to have_text('Build Your Own Lab')
    expect(page).to have_text('Things that Weserve does for you')
  end
end