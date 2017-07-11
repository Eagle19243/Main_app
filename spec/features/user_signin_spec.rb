require 'rails_helper'

feature 'Sing_in working on  "/users/sign_in" ' , js: true do
  let(:user) { create(:user, :confirmed_user) }

  scenario 'user logs in at "/users/sign_in" 'do
    visit '/users/sign_in'
    sign_in_form = find('.main-form #new_user')

    sign_in_form.fill_in 'user_email', with: user.email
    sign_in_form.fill_in 'user_password', with: 'secretadmin0password'
    sign_in_form.click_button 'Sign in'

    expect(page).to have_no_content 'Invalid Email or password.'
    expect(page).to have_current_path('/home', only_path: true)
    expect(page).to have_content('Signed in successfully.')
  end
end
