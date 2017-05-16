require 'rails_helper'

feature 'Normal Sign up', js: true do
  before do
    visit root_path
    click_pseudo_link 'Register'

    @modal = find('div#registerModal', visible: true)
  end

  context "When click 'Register' link" do
    scenario "Sign up popup appeared" do
      expect(@modal).to be_visible
    end

    context "When fill the fields and click 'Sign Up' button", vcr: { cassette_name: 'coinbase/wallet_creation' } do
      before do
        @user = FactoryGirl.build(:user)

        @before_count = User.count

        @modal.fill_in 'username', with: @user.username
        @modal.fill_in 'new_email', with: @user.email
        @modal.fill_in 'new_password', with: @user.password
        @modal.fill_in 'password_confirmation', with: @user.password
        @modal.click_button 'Sign up'
      end

      scenario "You have been registered" do
        expect(page).to have_text I18n.t 'devise.registrations.signed_up_but_unconfirmed'
        expect(User.count).not_to eq @before_count
      end

      scenario "You have been redirected to the 'Active Projects' page" do
        expect(page).to have_current_path(home_index_path)
      end

      scenario "Successful registration message appeared" do
        expect(page).to have_text I18n.t 'devise.registrations.signed_up_but_unconfirmed'
      end

      scenario "Confirmation email has been sent to you" do
        sleep 3
        last_delivery = ActionMailer::Base.deliveries.last
        expect(last_delivery.body.raw_source).to include "Welcome #{@user.email}"
        expect(last_delivery.body.raw_source).to include "You can confirm your account email"
      end
    end
  end
end
