require 'rails_helper'

feature 'Wallet modal working correctly', type: :feature, js: true, vcr: { cassette_name: 'bitgo' } do

  before do
    @user = FactoryGirl.create(:user)
    @user.confirmed_at = Time.now
    @user.save
    login_as(@user, :scope => :user, :run_callbacks => false)

    puts "success"
  end

  scenario 'wallet modal should appear' do
    visit root_path

    click_pseudo_link 'Active Projects'
    expect(page).to have_current_path(projects_path)

    modal = find('div#walletModal', visible: true)
    expect(modal).to be_visible
    expect(modal).to have_text('Welcome!')
  end
end