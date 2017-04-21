class ApplicationController < ActionController::Base

  rescue_from CanCan::AccessDenied do |exception|
    msg = Rails.env.production? ? 'Ooops. Seems you are not authorized for this action' : exception.message
    respond_to do |format|
     format.html { redirect_to main_app.root_url, notice: msg }
     format.json { render json: { message: msg }, status: :unauthorized }
     format.js { render json: { message: msg }, status: :unauthorized }
   end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    msg = Rails.env.production? ? 'Sorry we cannot find what you are looking for !' : exception.message
    respond_to do |format|
     format.html { redirect_to main_app.root_url, notice: msg }
     format.json { render json: { message: msg }, status: :not_found }
     format.js { render json: { message: msg }, status: :not_found }
   end
  end

  protect_from_forgery with: :exception
  around_filter :set_current_user
  after_action :flash_to_headers
  before_action :basic_http_auth

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
      unless params[:controller] == "visitors" || params[:controller] == "registrations" || params[:controller] == "sessions"
        redirect_to :controller => "visitors", :action => "restricted", :alert => "Admin only mode activated."
        flash[:notice] = "Admin only mode activated. You need to be an admin to make changes."
      end

      if params[:controller] == "visitors" && params[:action] == "index"
        redirect_to :controller => "visitors", :action => "restricted", :alert => "Admin only mode activated."
        flash[:notice] = "Admin only mode activated. You need to be an admin to make changes."
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
    if Rails.env.staging? && ENV['HTTP_BASIC_AUTHENTICATION_PASSWORD'].present?
      http_basic_authenticate_with :name => 'weserve', :password => ENV.fetch("HTTP_BASIC_AUTHENTICATION_PASSWORD")
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
end
