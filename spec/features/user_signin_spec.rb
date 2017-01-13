require 'rails_helper'

feature 'Sing_in working on  "/users/sign_in" ' , js: true , vcr: { cassette_name: 'bitgo' } do
  scenario 'lets user log in "/users/sign_in" 'do
    visit '/users/sign_in'
    @user = FactoryGirl.create(:user)
    @user.confirmed_at = Time.now
    @user.save
    find(:xpath ,'//*[@id="sign_in_show"]/div/div/div/div[2]/form/div[1]/input' , :match => :first).set(@user.email)
    find(:xpath ,'//*[@id="sign_in_show"]/div/div/div/div[2]/form/div[2]/input' , :match => :first).set(@user.password)
    page.execute_script("$(#{'[name="commit"]'}).click()")
    expect(page).to have_no_content 'Invalid Email or password.'
  end
end