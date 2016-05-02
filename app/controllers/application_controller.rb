class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :admin_only_mode

    #a filter to enable private mode in which the app is available only to admins
    def admin_only_mode
      unless current_user.try(:admin?)
        unless params[:controller] == "visitors" || params[:controller] == "registrations" || params[:controller] == "devise/sessions"
          redirect_to :controller => "visitors", :action => "restricted", :alert => "Admin only mode activated."
          flash[:notice] = "Admin only mode activated. You need to be an admin to make changes."
        end

        if params[:controller] == "visitors" && params[:action] == "index"
          redirect_to :controller => "visitors", :action => "restricted", :alert => "Admin only mode activated."
          flash[:notice] = "Admin only mode activated. You need to be an admin to make changes."
        end
      end

      puts params
      puts params[:controller] == "devise/sessions"
    end

    def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:name, :email, :password,
      :password_confirmation, :current_password, :picture, :company, :country, :description, :first_link, :second_link, :third_link, :fourth_link, :city, :picture_cache, :phone_number) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:name, :email, :password,
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
