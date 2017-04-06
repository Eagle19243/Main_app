require 'rails_helper'

feature "Project Page Plan Tab", js: true do
  before do
    @user = FactoryGirl.create(:user, confirmed_at: Time.now)
    @project = FactoryGirl.create(:project, user: @user)
    @task = FactoryGirl.create(:task, project: @project)
    @wallet_address = FactoryGirl.create(:wallet_address, task: @task)
  end

  context "As logged in user" do
    before do
      login_as(@user, :scope => :user, :run_callbacks => false)
    end

    context "When you visit the project page" do
      before do
        visit project_path(@project)
        click_link("Tasks")
        @task_area = find("#Tasks")
      end

      scenario "Then you can see 'Fund' button on the task tab" do
       expect(@task_area.find(".pr-card .fund-do-btns", match: :first)).to have_content "FUND"
      end

      context "When you click 'Fund' button" do
        before do
          @task_area.find(".pr-card .fund-do-btns", match: :first).click_button "FUND"
          @fund_modal = find("#taskFundModal", visible: true)
        end

        scenario "Then the fund modal appeared" do
          expect(@fund_modal).to be_visible
        end

        scenario "Then you can donate with credit card" do
          expect(@fund_modal).to have_content "Donate with credit card"
        end

        context "When you clcik 'Donate with credit card' button" do
          before do
            @valid_card_number = "4242424242424242"
            @invalid_card_number = "1111111111111111"
            @expiry = 5.years.from_now.strftime('%m/%Y')
            @cvv = "211"

            @fund_modal.click_button "Donate with credit card"
            @card_modal = find(".modal-fund__stripe")

            @fund_modal.fill_in "amount", with: 10

            @card_modal.fill_in('card_expiry', with: @expiry)
            @card_modal.fill_in('card_code', with: @cvv)
          end

          scenario "Then it is available to donate with credit card" do
            expect(@card_modal).to be_visible
          end

          context "When you fill in the valid card information" do
            before do
              allow_any_instance_of(Payments::BTC::WalletHandler).to receive(:get_wallet_balance).and_return(1000)

              @card_modal.fill_in('card_number', with: @valid_card_number)
              @card_modal.find("._donate").click
            end

            scenario "Then you can donate the task with the credit card" do
              wait_for_ajax
              sleep 2

              expect(@card_modal).not_to be_visible
            end
          end

          context "When you fill in the invalid card information" do
            before do
              @card_modal.fill_in('card_number', with: @invalid_card_number)

              @card_modal.find("._donate").click
            end

            scenario "Then it's failed to donate with the card" do
              wait_for_ajax
              expect(@card_modal).to have_content "Your card number is incorrect."
            end
          end
        end
      end
    end
  end
end
