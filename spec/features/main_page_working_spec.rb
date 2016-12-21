require 'rails_helper'

feature 'Home page working or not  ', :js => true do
  scenario 'Website working or not' do
    visit '/'
    page.status_code == '200'
  end
end

