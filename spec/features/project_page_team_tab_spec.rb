require 'rails_helper'

feature "Project Page Team Tab", js: true do

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
        find(".tabs-menu__inner li a[data-tab='team']").trigger("click")
      end

      scenario "Then the user's card is displayed" do
        expect(find(".member-box")).to have_content @project.user.name
      end
    end
  end
end
