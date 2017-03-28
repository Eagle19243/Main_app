require 'rails_helper'

feature "My Wallet", js: true, vcr: { cassette_name: 'bitgo' } do

  context "As logged in user" do
    before do
      @current_user = FactoryGirl.create(:user, confirmed_at: Time.now)
      @projects = FactoryGirl.create_list(:project, 2, user: @current_user)

      login_as(@current_user, :scope => :user, :run_callbacks => false)
    end

    context "When you visit the Home page and the click your name link" do
      before do
        visit '/'
        find("a.pr-user").trigger("click")

        @dropdown = find("ul.dropdown-menu")
      end

      scenario "Then you can see the 'My Profile' link in the top right dropdown menu" do
        expect(@dropdown).to be_visible
      end

      context "When you click the 'My Wallet' link while having a wallet which has transactions" do
        before do
          VCR.use_cassette("bitgo_wallet_transactions_present") do
            @dropdown.click_link "My Wallet"
          end
        end

        scenario "Then you are redirected to the profile page" do
          expect(page).to have_current_path(my_wallet_user_path(@current_user))
        end

        scenario "Then you can see the wallet receiving address" do
          @current_user.reload

          receive_wallet_address = find(".s-wallet__btc-address")
          expect(receive_wallet_address).to have_content @current_user.user_wallet_address.receiver_address
        end

        scenario "And you see a list of transactions" do
          expect(page).to have_selector(".t-transactions__row", count: 22)
        end
      end

      context "When you click the 'My Wallet' link while having a wallet which have no transactions" do
        before do
          VCR.use_cassette("bitgo_wallet_transactions_empty") do
            @dropdown.click_link "My Wallet"
          end
        end

        scenario "Then you are redirected to the profile page" do
          expect(page).to have_current_path(my_wallet_user_path(@current_user))
        end

        scenario "Then you can see the wallet receiving address" do
          @current_user.reload

          receive_wallet_address = find(".s-wallet__btc-address")
          expect(receive_wallet_address).to have_content @current_user.user_wallet_address.receiver_address
        end

        scenario "And you see a message that there is no transactions" do
          expect(page).to have_content("No Transaction")
        end
      end
    end
  end
end
