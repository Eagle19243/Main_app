class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications
    @notifications.unread.update_all(:read => true)
  end

  def destroy
    @notification = Notification.find(params[:id])
    respond_to do |format|
      if @notification.destroy
        format.json { render json: @notification.id, status: :ok }
      else
        format.json { render status: :internal_server_error }
      end
    end
  end
end
