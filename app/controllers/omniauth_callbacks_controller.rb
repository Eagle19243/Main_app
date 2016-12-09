class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      set_mediawiki_cookie @user
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end

  def twitter
    auth = env["omniauth.auth"]
    @user = User.find_for_twitter_oauth(request.env["omniauth.auth"],current_user)
    if @user.persisted?
      set_mediawiki_cookie @user
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Twitter"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.twitter_uid"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end

  def google_oauth2
    @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      set_mediawiki_cookie @user
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.google_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end

  private

  def set_mediawiki_cookie user
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    secret = settings['mediawiki']['secret']
    domain = settings['mediawiki']['domain']

    cookies.permanent[:_ws_user_id] = {
      value: user.id,
      domain: domain
    }

    cookies.permanent[:_ws_user_name] = {
      value: user.username,
      domain: domain
    }

    cookies.permanent[:_ws_user_token] = {
      value: Digest::MD5.hexdigest("#{secret}#{user.id}#{user.username}"),
      domain: domain
    }
  end

end