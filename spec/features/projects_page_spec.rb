require 'rails_helper'

feature 'Projects page is working for anonymous user', type: :feature, js: true do
  scenario 'Website is working or not' do
    visit '/'
    page.status_code == '200'
  end

  scenario 'Anonymous user should visit projects page' do
    visit projects_path

    expect(page).to have_text('Browse Projects')
    expect(page).to have_link('Explore projects')
  end

  scenario 'should redirect to active projects page' do
    visit '/'

    page.find('.header-link._active-project').click
    expect(page).to have_current_path(projects_path)
  end
end
