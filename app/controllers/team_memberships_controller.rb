class TeamMembershipsController < ApplicationController
  
  def update
    @team_membership = TeamMembership.find_by(params[:id])

    respond_to do |format|
      if @team_membership.update_attributes(update_params)
        NotificationsService.send_become_admin_notification(@team_membership)
        format.json { respond_with_bip(@team_membership) }
      else
        format.json { respond_with_bip(@team_membership) }
      end
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def update_params
      params.require(:team_membership).permit(:role)
    end
end
