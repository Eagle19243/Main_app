class SessionsController < Devise::SessionsController

  respond_to :json

  after_action :after_login, only: :create
  after_action :after_logout, only: :destroy
  after_action :reset_session, only: :new

  def after_login
    secret = ENV['mediawiki_secret']
    domain = ENV['mediawiki_domain']
    cookie_prefix = Rails.env.staging? ? 'staging' : ''

    cookies.permanent["#{cookie_prefix}_ws_user_id"] = {
        value: current_user.id,
        domain: domain
    }

    cookies.permanent["#{cookie_prefix}_ws_user_name"] = {
        value: current_user.username,
        domain: domain
    }

    cookies.permanent["#{cookie_prefix}_ws_user_token"] = {
        value: Digest::MD5.hexdigest("#{secret}#{current_user.id}#{current_user.username}"),
        domain: domain
    }
  end

  def after_logout
    domain = ENV['mediawiki_domain']

    cookies.delete(:_ws_user_id, domain: domain)
    cookies.delete(:_ws_user_name, domain: domain)
    cookies.delete(:_ws_user_token, domain: domain)
  end

end
