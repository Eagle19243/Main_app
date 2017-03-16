class ConfirmationsController < Devise::ConfirmationsController
  
  # We use this to autologin user when they confirm their email, although Devise does not recommend this behaviour
  def show
    super do |resource|
      sign_in(resource)
    end
  end
end
