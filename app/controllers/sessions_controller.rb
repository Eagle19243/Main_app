class SessionsController < Devise::SessionsController

  respond_to :json

  after_action :after_login, :only => :create
  after_action :after_logout, :only => :destroy

  def after_login
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    secret = settings['mediawiki']['secret']
    domain = settings['mediawiki']['domain']

    cookies.permanent[:_ws_user_id] = {
        value: current_user.id,
        domain: domain
    }

    cookies.permanent[:_ws_user_name] = {
        value: current_user.username,
        domain: domain
    }

    cookies.permanent[:_ws_user_token] = {
        value: Digest::MD5.hexdigest("#{secret}#{current_user.id}#{current_user.username}"),
        domain: domain
    }
  end

  def after_logout
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    domain = settings['mediawiki']['domain']

    cookies.delete(:_ws_user_id, domain: domain)
    cookies.delete(:_ws_user_name, domain: domain)
    cookies.delete(:_ws_user_token, domain: domain)
  end

end