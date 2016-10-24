class AdminInvitationsController < ApplicationController
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

  private

  def create_params
    params.require(:admin_invitation).permit(:user_id, :project_id)
  end
end
