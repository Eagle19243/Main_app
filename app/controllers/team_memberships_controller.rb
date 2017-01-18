class TeamMembershipsController < ApplicationController
  load_and_authorize_resource :except => [:destroy]

  def update
    @team_membership = TeamMembership.find(params[:id])

    if @team_membership.role != "lead_editor" && update_params["role"] == "lead_editor"
      update_type = "grant"
    elsif @team_membership.role == "lead_editor" && update_params["role"] != "lead_editor"
      update_type = "revoke"
    end

    respond_to do |format|
      if @team_membership.update(update_params)
        project = @team_membership.team.project
        user    = @team_membership.team_member

        project.grant_permissions user.username if update_type == "grant"
        project.revoke_permissions user.username if update_type == "revoke"

        format.json { respond_with_bip(@team_membership) }
      else
        format.json { respond_with_bip(@team_membership) }
      end
    end
  end

  def destroy
    @team_membership = TeamMembership.find(params[:id])
    respond_to do |format|
      if current_user.id == @team_membership.team.project.user_id || (@team_membership.team.project.user_id != current_user.id && @team_membership.role == 1)
        if @team_membership.destroy
          format.json { render json: @team_membership.id, status: :ok }
        else
          format.json { render status: :internal_server_error }
        end
      else
        format.json { render status: 'You can\'t  delete this team member ' }
      end
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def update_params
    params.require(:team_membership).permit(:role)
  end
end
