class TeamMembershipsController < ApplicationController
  load_and_authorize_resource :except => [:destroy]

  def update
    @team_membership = TeamMembership.find(params[:id])

    authorize! :update, @team_membership

    # When a user has more roles, he can't update his role in a way that he has 2 same roles
    all_team_memberships = @team_membership.team_member.team_memberships.where(team: @team_membership.team)
    forbidden_roles = (all_team_memberships - [@team_membership]).map(&:role)
    if forbidden_roles.include? update_params["role"]
      respond_to do |format|
        format.json { respond_with_bip(@team_membership) }
      end
    else

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
  end

  def destroy
    @team_membership = TeamMembership.find(params[:id])

    authorize! :destroy, @team_membership

    respond_to do |format|
      if current_user.id == @team_membership.team.project.user_id || (@team_membership.team.project.user_id != current_user.id && @team_membership.role == 1)
        if @team_membership.destroy

          Chatroom.remove_user_from_project_chatroom(@team_membership.team.project, @team_membership.team_member)

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
