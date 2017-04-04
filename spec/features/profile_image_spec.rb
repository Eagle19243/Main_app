require 'rails_helper'

feature "Profile Image", js: true do
  before do
    @users = FactoryGirl.create_list(:user, 2, confirmed_at: Time.now)
    @user = @users.first
    @another_user = @users.last
  end
  
  context "As a logged in user" do
    before do      
      login_as(@user, :scope => :user, :run_callbacks => false)   
    end

    context "When you visit your profile page" do
      before do
        visit user_path(@user)
        @edit_link = find(".btn-edit-image._profile")
      end

      scenario "Then 'Edit My Profile Image' link not appeared" do
        expect(@edit_link).not_to be_visible
      end

      context "When you hover mouse on the profile image" do
        before do
          @image_div = find(".profile-hero__user-portrait._signed-in")
          @image_div.hover          
        end

        scenario "Then 'Edit My Profile Image' link appeared" do
          expect(@edit_link).to be_visible
        end

        context "When you click 'Edit My Profile Image' link" do
          before do
            @edit_link.click
            wait_for_ajax

            @modal = find(".modal-edit-img")
          end

          scenario "Then 'Edit Profile Image' modal appeared" do
            expect(@modal).to be_visible
          end

          context "When you choose another image and click 'SAVE CHANGES' button" do
            before do
              @image = "user_photo.png"
              @modal.attach_file 'user[picture]', Rails.root + "spec/fixtures/#{@image}"
              wait_for_ajax

              @modal.click_button "Save Changes"
            end

            scenario "Then your profile image has been changed" do
              expect(@image_div).to have_xpath("//img[contains(@src, @image)]")
            end
          end
        end
      end
    end

    context "When you visit other's profile page" do
      before do
        visit user_path(@another_user)
      end

      scenario "Then 'Edit My Profile Image' link not appeared" do
        expect(page).not_to have_selector(".btn-edit-image._profile")
      end

      context "When you hover mouse on the profile image" do
        before do
          @image_div = find(".profile-hero__user-portrait")
          @image_div.hover          
        end

        scenario "Then 'Edit My Profile Image' link not appeared" do
          expect(page).not_to have_selector(".btn-edit-image._profile")
        end
      end
    end
  end

  context "As an anonymous user" do
    context "When you visit other's profile page" do
      before do
        visit user_path(@another_user)
      end

      scenario "Then 'Edit My Profile Image' link not appeared" do
        expect(page).not_to have_selector(".btn-edit-image._profile")
      end

      context "When you hover mouse on the profile image" do
        before do
          @image_div = find(".profile-hero__user-portrait")
          @image_div.hover          
        end

        scenario "Then 'Edit My Profile Image' link not appeared" do
          expect(page).not_to have_selector(".btn-edit-image._profile")
        end
      end
    end
  end
end
