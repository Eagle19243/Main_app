class SessionsController < Devise::SessionsController

  def new
    reset_session
    super
  end

end
