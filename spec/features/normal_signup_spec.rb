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

        sign_up_form = @modal.find('#sign_up_show')
        sign_up_form.fill_in 'user_username', with: @user.username
        sign_up_form.fill_in 'user_email', with: @user.email
        sign_up_form.fill_in 'user_password', with: @user.password
        sign_up_form.fill_in 'user_password_confirmation', with: @user.password
        sign_up_form.click_button 'Sign up'

        sleep 1
      end

      scenario "You have been registered" do
        expect(page).to have_text I18n.t 'devise.registrations.signed_up_but_unconfirmed'
        expect(User.count).not_to eq @before_count
      end

      scenario "You have been redirected to the 'Active Projects' page" do
        expect(page).to have_current_path(home_index_path, only_path: true)
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
