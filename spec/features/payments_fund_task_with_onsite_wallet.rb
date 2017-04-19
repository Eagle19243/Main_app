require 'rails_helper'

feature "Project Page Plan Tab", js: true do
  before do
    @user = FactoryGirl.create(:user, confirmed_at: Time.now)
    @project = FactoryGirl.create(:project, user: @user)
    @task = FactoryGirl.create(:task, project: @project)
    @wallet_address = FactoryGirl.create(:wallet_address, task: @task)

    # Set balance for user's wallet
    @user.user_wallet_address.update_attribute(:current_balance, 450000)
  end

  context "As lgged in user" do
    before do
      login_as(@user, :scope => :user, :run_callbacks => false)
    end

    context "When you visit the project page" do
      before do
        visit project_path(@project)
        @plan_area = find(".tabs-wrapper__plan")
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

        scenario "And this modal is showing user's wallet budget" do
          @wallet_budget = @fund_modal.find(".modal-fund__balance", visible: true)
          expect(@wallet_budget.text).to eq("BTC Wallet (0.0045)")
        end

        scenario "And this modal have hidden field with task wallet" do
          @task_wallet = @fund_modal.find("#wallet_transaction_user_wallet")
          expect(@task_wallet.value).to eq(@wallet_address.receiver_address)
        end

        scenario "And this modal suggests to enter BTC amount" do
          expect(@fund_modal).to have_content "Enter BTC Amount to Send"
        end

        scenario "And donate with bitcoin button appears" do
          expect(@fund_modal).to have_content "Donate with bitcoin"
        end
        
        context "When you donate with bitcoin" do
          before do
            @amount_field = @fund_modal.find("#wallet_transaction_amount")
          end

          scenario "It's possible to set BTC amount" do
            @amount_field.set(0.001)
            expect(@amount_field.value).to eq("0.001")
          end
        end
      end
    end
  end
end
