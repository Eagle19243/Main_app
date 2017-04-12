class ConfirmationsController < Devise::ConfirmationsController

  # We use this to autologin user when they confirm their email, although Devise does not recommend this behaviour
  def show
    super do |resource|
      sign_in(resource)
      set_cookies(resource)
    end
  end

  def set_cookies(resource)
    secret = ENV['mediawiki_secret']
    domain = ENV['mediawiki_domain']
    cookie_prefix = Rails.env.staging? ? 'staging' : ''

    cookies.permanent["#{cookie_prefix}_ws_user_id"] = {
        value: resource.id,
        domain: domain
    }

    cookies.permanent["#{cookie_prefix}_ws_user_name"] = {
        value: resource.username,
        domain: domain
    }

    cookies.permanent["#{cookie_prefix}_ws_user_token"] = {
        value: Digest::MD5.hexdigest("#{secret}#{resource.id}#{resource.username}"),
        domain: domain
    }
  end

end
