require 'rails_helper'

feature 'Home page is working for anonymous user', type: :feature, js: true do
  scenario 'Website is working or not' do
    visit '/'
    page.status_code == '200'
  end

  scenario 'Anonymous user visits home page' do
    visit root_path
    expect(page).to have_text( I18n.t 'landing.hero-title' )
    expect(page).to have_text( I18n.t 'commons.login' )
    expect(page).to have_text( I18n.t 'commons.register' )
    expect(page).to have_text( I18n.t 'landing.hero-collaboration-title' )
  end
end
