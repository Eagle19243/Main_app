require 'rails_helper'

feature 'Sing_in working on  "/users/sign_in" ' , js: true do
  let(:user) { create(:user, :confirmed_user) }

  scenario 'user logs in at "/users/sign_in" 'do
    visit '/users/sign_in'
    find(:xpath ,'//*[@id="sign_in_show"]/div/div/div/div[2]/form/div[1]/input' , match: :first).set(user.email)
    find(:xpath ,'//*[@id="sign_in_show"]/div/div/div/div[2]/form/div[2]/input' , match: :first).set(user.password)

    find('#sign_in_show button[name="commit"]', match: :first).click
    sleep 1

    expect(page).to have_no_content 'Invalid Email or password.'
    expect(current_path).to eq('/home')
    expect(page).to have_content('Signed in successfully.')
  end
end
