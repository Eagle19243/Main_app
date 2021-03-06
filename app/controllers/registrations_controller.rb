class RegistrationsController < Devise::RegistrationsController
  respond_to :json


  def create
    super
    @user.create_wallet! if @user.save
  end

  private

  def sign_up_params
    params.require(:user).permit(:username, :email, :password,
      :password_confirmation, :current_password, :picture, :company, :country, :description, :first_link, :second_link, :third_link, :fourth_link, :city, :phone_number)
  end

  def account_update_params
    params.require(:user).permit(:username, :email, :password,
      :password_confirmation, :current_password, :picture, :company,
      :country, :description, :first_link, :second_link, :third_link,
      :fourth_link, :city, :phone_number, :bio, :facebook_url, :twitter_url,
      :linkedin_url, :picture_cache)
  end
end
