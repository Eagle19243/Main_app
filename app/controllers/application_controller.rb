class ApplicationController < ActionController::Base

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, notice: exception.message
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    redirect_to main_app.root_url, notice: exception.message
  end

  protect_from_forgery with: :exception
  around_filter :set_current_user

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

    helper_method :service_action, :service_name

end
