require 'rails_helper'

feature 'After login ' do
  before do 
    @user = FactoryGirl.create(:user)
    @user.confirmed_at = Time.now
    @user.save
    login_as(@user, :scope => :user, :run_callbacks => false)

    puts "success"
  end
  scenario 'Start a project is working', js: true, vcr: { cassette_name: 'bitgo' } do
    visit root_path

    # have_text("Browse Projects")
    # click_pseudo_link 'Login'
    # modal = find('div#registerModal', visible: true)
    # puts "\n button"
    # puts modal.find_button('Sign in').inspect
    # within('div#registerModal') do
    #   fill_in 'email', with: 'admin0@example.com'
    #   fill_in 'password', with: 'secretadmin0password'
    #   click_button 'Sign in'
    # end
    
    # # #l = find('a#start_project_link')
    # # find('.fa-envelope-o')

    # # click_pseudo_link 'Start a Project'
      

    # # modal = find('div#startProjectModal', visible: true)

    # # expect(modal).to be_visible
    # # expect(modal).to has_css?('input.btn-primary')
    # # within('div#startProjectModal') do
    # #   fill_in 'project[title]', with: 'Test project'
    # #   fill_in 'project[short_description]', with: 'short_description'
    # #   fill_in 'project[country]', with: 'usa'
    # #   click_button 'Create Project'
    # # end
    # Timeout.timeout(Capybara.default_max_wait_time) do
    #   loop until page.evaluate_script('jQuery.active').zero?

    # end
    # #visit root_path
    # #page.evaluate_script("window.location.reload()")
    # puts "modal:"
    # puts modal['innerHTML']
    # puts "header:"
    # puts page.find('div.header-wrap')['innerHTML']
    # Timeout.timeout(Capybara.default_max_wait_time) do
    #   loop until page.has_link? 'Start a Project'
    # end
    click_pseudo_link 'Start a Project'
    modal = find('div#startProjectModal', visible: true)
    within('div#startProjectModal') do
      fill_in 'project[title]', with: 'Test_project'
      fill_in 'project[short_description]', with: 'short_description'
      fill_in 'project[country]', with: 'usa'
      attach_file 'project[picture]', Rails.root + "spec/fixtures/photo.png"
      click_button 'Create Project'
    end
    
    wait_for_ajax
    puts modal['innerHTML']
    puts page.find('.project-wrap')['innerHTML']
    # modal.click_button '&times;'
    
    
  end
end
