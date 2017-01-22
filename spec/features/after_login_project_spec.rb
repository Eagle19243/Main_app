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

    click_pseudo_link 'Start a Project'
    modal = find('div#startProjectModal', visible: true)
    within('div#startProjectModal') do
      fill_in 'project[title]', with: 'Test_project123'
      fill_in 'project[short_description]', with: 'short_description123'
      fill_in 'project[country]', with: 'test_country123'
      attach_file 'project[picture]', Rails.root + "spec/fixtures/photo.png"
      click_button 'Create Project'
    end

    modal = find('div#startProjectModal', visible: true)
    # Timeout.timeout(Capybara.default_max_wait_time) do
    #   loop until page.evaluate_script('jQuery.active').zero?
    # end

    visit taskstab_project_path(1)
    find('div#projectInviteModal').find('.modal-default__close').click
    expect(page).to have_content "short_description123"
    
    # using_wait_time(2) do
    #   click_link 'editSource'
    #   expect(page).to have_content "Test_project123"
    # end

  end
end
