require 'rails_helper'

feature 'Facebook login', js: true do
  before do
    visit '/'
    click_pseudo_link 'Login'

    @modal = find('div#registerModal', visible: true)
  end

  scenario "Sign in popup appeared when click login link" do
    expect(@modal).to be_visible
  end

  context "as already registered user" do
    before do
      @user = FactoryGirl.create(:user, confirmed_at: Time.now)

      click_facebook_login(@user)
    end

    scenario "log in with the user's facebook account" do
      expect(page).to have_selector("span.user-dropdown__name")
    end
  end

  context "as new user" do
    before(:each) do
      @user = FactoryGirl.build(:user)

      @before_count = User.count

      click_facebook_login(@user)
    end

    scenario "registered with the user's facebook account" do
      expect(User.count).not_to eq @before_count
    end

    scenario "log in with the user's facebook account" do
      expect(page).to have_selector("span.user-dropdown__name")
    end
  end

  def click_facebook_login(user)
    credential = OmniAuth::AuthHash.new({
      :provider => :facebook,
      :uid     => "1234",
      :info =>  {
                :email => user.email,
                :name => user.name,
                :image => "http://foo_image"
                },
      :extra => {
                :link => "facebook.com"
                }
    })

    set_omniauth(credential)

    @modal.find(".modal-sign__col._sign-in .m-social__item.facebook a[href='/users/auth/facebook']").click
  end
end
