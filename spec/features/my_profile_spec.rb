require 'rails_helper'

feature "My Profile", js: true do

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

      context "When you click the 'My Profile' link" do
        before do
          @dropdown.click_link "My Profile"
          @profile_header = find(".profile-hero")
          @profile_bio = find(".bio-wrapper")
        end

        scenario "Then you are redirected to the profile page" do
          expect(page).to have_current_path(user_path(@current_user))
        end

        scenario "Then you can see your profile info in the header part" do
          expect(@profile_header).to have_content @current_user.display_name
        end

        scenario "Then you can see the list of projects" do
          projects_part = find(".profile-projects")

          @projects.each do |project|
            expect(projects_part).to have_content project.title
          end
        end

        scenario "Then your location is editable" do
          expect(@profile_header).to have_selector("a#edit-location-pencil")
        end

        scenario "Then your bio is editable" do
          expect(@profile_bio).to have_selector("#bio-edit-pencil")
        end

=begin
        context "When you click your location edit link" do
          before do
            find("a#edit-location-pencil").trigger("click")
            @location_form = find(".profile-hero__user-location._open-edit-form")
          end

          scenario "Then your location is availble to be changed" do
            expect(@location_form).to be_visible
          end

          context "When you change your location and click 'Save' button" do
            before do
              @location = "new location"
              @location_form.fill_in 'city', with: @location

              @location_form.find('input[type="submit"]').click
            end

            scenario "Then your location has been changed" do
              expect(@profile_header).to have_content @location
            end
          end
        end
=end

        context "When you click your bio edit link" do
          before do
            @profile_bio.find("#bio-edit-pencil").trigger("click")
            @bio_form = find(".profile-bio form")
          end

          scenario "Then your bio is availble to be changed" do
            expect(@bio_form).to be_visible
          end

          context "When you change your bio and click 'Save' button" do
            before do
              @bio = "new bio"
              @bio_form.fill_in 'bio', with: @bio

              @bio_form.find('input[type="submit"]').click
            end

            scenario "Then your bio has been changed" do
              expect(@profile_bio).to have_content @bio
            end
          end
        end
      end
    end
  end
end
