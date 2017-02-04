require 'rails_helper'

feature "Project Page Plan Tab", js: true, vcr: { cassette_name: 'bitgo' } do
  before do
    @user = FactoryGirl.create(:user, confirmed_at: Time.now)
    @project = FactoryGirl.create(:project, user: @user)
    @task = FactoryGirl.create(:task, project: @project)
    @wallet_address = FactoryGirl.create(:wallet_address, task: @task)
  end

  context "As lgged in user" do
    before do
      login_as(@user, :scope => :user, :run_callbacks => false)
    end

    context "When you visit the project page" do
      before do
        visit project_path(@project)
        @plan_area = find("#Plan")
      end

      scenario "Then you can see 'Fund' button in the task block" do
        expect(@plan_area.find(".pr-card .fund-do-btns")).to have_content "FUND"
      end

      context "When you click 'Fund' button" do
        before do
          @plan_area.find(".pr-card .fund-do-btns").click_button "FUND"
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
            @expiry_year = 2020
            @expiry_month = 12
            @cvv = "211"

            @fund_modal.click_button "Donate with credit card"
            @card_modal = find(".modal-fund__stripe")

            @fund_modal.fill_in "amount", with: 10

            find('[data-stripe="exp_month"]').set @expiry_month
            find('[data-stripe="exp_year"]').set @expiry_year

            @card_modal.fill_in "cardCvc", with: @cvv
          end

          scenario "Then it is available to donate with credit card" do
            expect(@card_modal).to be_visible
          end

          context "When you fill in the valid card information" do
            before do
              allow_any_instance_of(Object).to receive(:get_reserve_wallet_balance).and_return(1000)

              @card_modal.fill_in "cardNumber", with: @valid_card_number

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
              @card_modal.fill_in "cardNumber", with: @invalid_card_number

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