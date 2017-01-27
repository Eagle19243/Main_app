require 'rails_helper'

feature "Project Page Team Tab", js: true, vcr: { cassette_name: 'bitgo' } do

  context "When you visit a project page as logged in user" do
    before do
      @users = FactoryGirl.create_list(:user, 2, confirmed_at: Time.now)
      @users.each do |user|
        @projects = FactoryGirl.create_list(:project, 2, user: user)
      end

      @current_user = @users.first
      @another_user = @users.last
      @another_user.admin!

      @project = @current_user.projects.first

      login_as(@current_user, :scope => :user, :run_callbacks => false)
      
      visit project_path @project
    end

    scenario "Then you can see 'Team' tab" do
      expect(find(".tabs-menu__inner")).to have_content "Team"
    end

    context "When you navigate to 'Team' tab" do
      before do
        find(".tabs-menu__inner li a[data-tab='Team']").trigger("click")
      end

      scenario "Then the user's card is displayed" do
        expect(find(".member-box")).to have_content @project.user.name
      end

      context "When you click 'Invite Admin' button" do
        before do
          search_container = find("#userSearchPopupContainer")
          search_container.click_button "Invite Admin"
          @modal = find("#userSearchPopup", visible: true)
        end

        scenario "Then the 'Search Users' popup appeared" do
          expect(@modal).to be_visible
        end

        context "When you input admin user and click 'SEARCH' button" do
          before do
            @modal.fill_in 'search', with: @another_user.name

            allow_any_instance_of(Sunspot::Rails::StubSessionProxy::Search).to receive(:results).and_return([@another_user])

            @modal.click_button 'Search'
          end

          scenario "Then you can see admin users" do
            expect(@modal).to have_content @another_user.name
          end

          scenario "Then you can invite an admin user" do
            @modal.find(".userSearchResults").click_button "Invite"

            wait_for_ajax

            expect(@modal.find(".userSearchResults")).to have_content "INVITED"
          end
        end
      end
    end
  end
end