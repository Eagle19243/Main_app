class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :update, :destroy]

  def index
    @teams = Team.all
  end

  def show
  end

  # GET /teams/new
  def new
    @team = Team.new
  end

  def create
    @team = Team.new(team_params)

    respond_to do |format|
      if @team.save
        format.html { redirect_to @team, notice: 'Team was successfully created.' }
        format.json { render :show, status: :created, location: @team }
      else
        format.html { render :new }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to @team, notice: 'Team was successfully updated.' }
        format.json { render :show, status: :ok, location: @team }
      else
        format.html { render :edit }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @team.destroy
    respond_to do |format|
      format.html { redirect_to teams_url, notice: 'Team was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def remove_membership
    @team_membership = TeamMembership.find(params[:id])
    @team_membership.destroy
    respond_to do |format|
      format.html { redirect_to teams_url, notice: 'Team member  was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def team_memberships
    @project = Project.find(params[:project_id])
    @project_team = @project.team
    @add_member = true
    case @project_team.team_members.include?(current_user)
    when true
      @team_membership = @project_team.team_memberships.where(team_member_id: current_user.id).first
      @project_team.team_memberships.destroy(@team_membership) unless @team_membership.nil?
      @add_member = false
    else
      new_member = TeamMembership.create(team_member_id: current_user.id, team_id: @project_team.id)
      new_member.save
      @add_member = true
    end
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def users_search
    @project = Project.find(params[:project_id])
    @search = Sunspot.search(User) do
      fulltext params[:search]
    end
    @results = @search.results
    respond_to do |format|
      format.js
    end
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
