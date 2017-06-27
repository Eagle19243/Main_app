class ApplicationController < ActionController::Base

  rescue_from CanCan::AccessDenied do |exception|
    msg = Rails.env.production? ? t('controllers.cancan_access_denied') : exception.message
    respond_to do |format|
      format.html { redirect_to main_app.root_url, notice: msg }
      format.json { render json: { message: msg }, status: :unauthorized }
      format.js { render json: { message: msg }, status: :unauthorized }
      format.any { redirect_to main_app.root_url, notice: msg }
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    msg = Rails.env.production? ? t('controllers.active_record_not_found') : exception.message
    respond_to do |format|
      format.html { redirect_to main_app.root_url, notice: msg }
      format.json { render json: { message: msg }, status: :not_found }
      format.js { render json: { message: msg }, status: :not_found }
      format.any { redirect_to main_app.root_url, notice: msg }
    end
  end

  rescue_from ActionController::ParameterMissing do |exception|
    msg = Rails.env.production? ? t('users.update.fail') : exception.message
    respond_to do |format|
      format.any { redirect_to main_app.root_url, status: 304, notice: msg }
    end
  end

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    msg = Rails.env.production? ? t('controllers.unauthorized_message') : exception.message
    respond_to do |format|
      format.html { redirect_to main_app.root_url, notice: msg }
      format.json { render json: { message: msg }, status: :not_found }
      format.js { render json: { message: msg }, status: :not_found }
      format.any { redirect_to main_app.root_url, notice: msg }
    end
  end

  protect_from_forgery with: :exception
  around_filter :set_current_user
  after_filter :user_activity
  after_action :flash_to_headers
  before_action :basic_http_auth
  before_action :set_locale
   
  def set_locale
    locale_prefered = current_user.preferred_language if current_user && (I18n.available_locales.map(&:to_s).include? current_user.preferred_language)
    locale_param = params[:locale] if (I18n.available_locales.map(&:to_s).include? params[:locale])
    I18n.locale = locale_param || locale_prefered || I18n.default_locale
  end

  def default_url_options(options = {})
    if (I18n.default_locale != I18n.locale) && (I18n.available_locales.map(&:to_s).include? params[:locale])
      {locale: I18n.locale}.merge options
    else
      {locale: nil}.merge options
    end
  end

  def after_sign_in_path_for(resource)
    # projects_path
    # For now after sign in, users should redirect to landing page.
    root_path
  end

  def set_current_user
    User.current_user = current_user
    yield
  ensure
    User.current_user = nil
  end

  def admin_only_mode
    unless current_user.try(:admin?)
      unless params[:controller] == 'visitors' || params[:controller] == 'registrations' || params[:controller] == 'sessions'
        redirect_to :controller => 'visitors', :action => 'restricted', :alert => t('controllers.admin_only_mode.admin_mode_activated')
      end

      if params[:controller] == 'visitors' && params[:action] == 'index'
        redirect_to :controller => 'visitors', :action => 'restricted', :alert => t('controllers.admin_only_mode.admin_mode_activated')
      end
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:name, :email, :password,
      :password_confirmation, :current_password, :picture, :company, :country, :description, :first_link, :second_link, :third_link, :fourth_link, :city, :picture_cache, :phone_number) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:name, :email, :password,
      :password_confirmation, :current_password, :picture, :company, :country, :description, :first_link, :second_link, :third_link, :fourth_link, :city, :picture_cache, :phone_number) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:name, :email, :password,
      :password_confirmation, :current_password, :picture, :company, :country, :description, :first_link, :second_link, :third_link, :fourth_link, :city, :picture_cache, :phone_number) }
  end

  def default_api_value
    t("#{service_name}.#{service_action}", :default => {})
  end

  def service_name
    params[:controller].gsub(/^.*\//, "")
  end

  def service_action
    params[:action]
  end

  def wallet_handler
    Payments::BTC::WalletHandler.new
  end

  def basic_http_auth
    if ENV['HTTP_BASIC_AUTHENTICATION_PASSWORD'].present?
      authenticate_or_request_with_http_basic do |user, password|
        user == 'weserve' && password == ENV["HTTP_BASIC_AUTHENTICATION_PASSWORD"]
      end
    end
  end

  helper_method :service_action, :service_name

  def flash_to_headers
    return unless request.xhr?

    messages ||= {}

    flash.each do |type, msg|
      css_type = 'alert'
      css_type = 'success' if type.to_s == 'notice'

      messages[css_type] = msg
    end

    response.headers['X-Messages'] = messages.to_json

    flash.discard # don't want the flash to appear when you reload page
  end

  private

  def user_activity
    current_user.try :update_attribute, :last_seen_at, Time.zone.now
  end
end
