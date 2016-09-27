class TeamMembershipsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update, :destroy]

  def update
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def team_params
      params.require(:team).permit(:name, :number_of_members, :number_of_projects, :mission)
    end
end
