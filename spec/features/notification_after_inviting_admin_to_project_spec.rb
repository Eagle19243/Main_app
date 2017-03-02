require 'rails_helper'

feature "Notification After Invite an Admin to the Project", js: true, vcr: { cassette_name: 'bitgo' } do
  before do
    users = FactoryGirl.create_list(:user, 2, confirmed_at: Time.now)
    @user = users.first
    @another_user = users.last

    @project = FactoryGirl.create(:project, user: @user)
  end

  context "As a logged in user who has been created the project" do
    before do
      login_as(@user, :scope => :user, :run_callbacks => false)      
    end

    context "When you visit the project page" do
      before do
        visit project_path(@project)
      end

      context "When you invite an admin to the project" do
        before do
          @old_notifications_count = Notification.count

          find(".tabs-menu__inner li a[data-tab='Team']").trigger("click")
          wait_for_ajax

          find("#userSearchPopupContainer").click_button "Invite Admin"

          @modal = find("#userSearchPopup")
          @modal.fill_in "search", with: @another_user.name

          @modal.click_button "Search"
          wait_for_ajax

          @modal.find("#new_admin_invitation").click_button "Invite"
          wait_for_ajax
        end

        scenario "Then a new notification has been created" do
          expect(Notification.count).to eq @old_notifications_count + 1
        end

        context "When you log in as invited admin and visit the main page" do
          before do
            login_as(@another_user, :scope => :user, :run_callbacks => false)

            visit '/'
          end

          context "When you navigate 'Notifications' page" do
            before do
              find(".notify-dropdown").click
              wait_for_ajax

              @dropdown = find(".b-dropdown", visible: true)

              @dropdown.find(".b-dropdown__link").click_link "See All Notifications"
            end

# TODO: possibly outdated, to be reviewed
=begin
            scenario "Then you can see the admin invite notification" do
              expect(page).to have_content "#{@user.name} invites you to become an admin on project #{@project.title}"
            end
=end
          end
        end
      end
    end
  end
end
