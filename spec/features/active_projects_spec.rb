require 'rails_helper'

feature "Active projects", js: true, vcr: { cassette_name: 'bitgo' } do

  context "As logged in user" do
    before do
      @user = FactoryGirl.create(:user, confirmed_at: Time.now)
      @projects = FactoryGirl.create_list(:project, 9, user: @user)

      login_as(@user, :scope => :user, :run_callbacks => false)
      
      visit root_path
    end

    context "When you click 'Active Projects' button" do
      before do
        visit projects_path
        @wallet_modal = find('div#walletModal', visible: true)
      end

      scenario "Then 'Download Wallet Keys' popup appeared" do        
        expect(@wallet_modal).to be_visible
      end

      scenario "Then you are redirected to the active projects page" do
        expect(page).to have_current_path(projects_path)
      end

      scenario "Then you can see the project cards" do
        @projects.each do |project|
          expect(page).to have_content project.title
        end
      end

      context "When you click a project card" do
        before do
          @wallet_modal.find("button.modal-default__close").click

          @project = @projects.first

          click_pseudo_link @project.title
        end

        scenario "Then you are directed to the project page" do
          expect(page).to have_current_path taskstab_project_path(@project, tab: "Plan")
        end
      end
    end
  end
end