class AdminInvitationsController < ApplicationController
  load_and_authorize_resource
  before_action :set_admin_invitation, only: [:accept, :reject]

  def create
    @admin_invitation = AdminInvitation.new(create_params)
    respond_to do |format|
      if @admin_invitation.save
        format.json { render json: @admin_invitation, status: :ok }
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def accept
    respond_to do |format|
      if @admin_invitation.update(status: AdminInvitation.statuses[:accepted])
        TeamService.add_admin_to_project(@admin_invitation.project, @admin_invitation.user)
        format.json { render json: @admin_invitation.id, status: :ok }
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def reject
    respond_to do |format|
      if @admin_invitation.update(status: AdminInvitation.statuses[:rejected])
        format.json { render json: @admin_invitation.id, status: :ok }
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_admin_invitation
    @admin_invitation = AdminInvitation.find(params[:id])
  end

  def create_params
    params.require(:admin_invitation).permit(:user_id, :project_id, :sender_id)
  end
end
