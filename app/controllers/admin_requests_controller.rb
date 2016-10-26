class AdminRequestsController < ApplicationController
  before_action :set_admin_invitation, only: [:accept, :reject]

  def create
    @admin_request = AdminRequest.new(create_params)
    respond_to do |format|
      if @admin_request.save
        format.json { render json: @admin_request, status: :ok }
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def accept
    @admin_request.update(status: AdminRequest.statuses[:accepted])
  end

  def reject
    @admin_request.update(status: AdminRequest.statuses[:rejected])
  end

  private

  def set_admin_invitation
    @admin_request = AdminRequest.find(params[:id])
  end

  def create_params
    params.require(:admin_request).permit(:user_id, :project_id)
  end
end
