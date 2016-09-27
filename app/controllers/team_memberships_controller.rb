class TeamMembershipsController < ApplicationController
  
  def update
    @team_membership = TeamMembership.find(params[:id])

    respond_to do |format|
      if @team_membership.update_attributes(update_params)
        format.json { respond_with_bip(@team_membership) }
      else
        format.json { respond_with_bip(@user) }
      end
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def update_params
      params.require(:team_membership).permit(:role)
    end
end
