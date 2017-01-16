class NotificationsController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  PER_LOAD_COUNT = 10

  def index
    @notifications = Notification.last(PER_LOAD_COUNT)
    Notification.where(:read => false).update_all(:read => true)
  end

  def load_older
    @notifications = current_user.notifications.where("id < ?", params[:first_notification_id]).last(PER_LOAD_COUNT)
    if !@notifications.empty?
      @all_notifications_displayed = @notifications.first.id == current_user.notifications.first.id ? true : false
    else
      @all_notifications_displayed = true
    end
    @all_notifications_displayed = false
    respond_to do |format|
      format.js
    end
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
