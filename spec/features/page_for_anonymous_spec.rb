require 'rails_helper'

feature 'Active projects for anonymous user' do
  scenario 'when anonymous user visits', js: true do
    visit '/'

    click_pseudo_link 'Active Projects'

    expect(page).to have_current_path(projects_path)
    
  end
end
