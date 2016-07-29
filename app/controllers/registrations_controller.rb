class RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password,
      :password_confirmation, :current_password, :picture, :company, :country, :description, :first_link, :second_link, :third_link, :fourth_link, :city, :phone_number)
  end

  def account_update_params
    params.require(:user).permit(:name, :email, :password,
      :password_confirmation, :current_password, :picture, :company,
      :country, :description, :first_link, :second_link, :third_link,
      :fourth_link, :city, :phone_number, :bio)
  end

end
