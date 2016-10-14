class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update, :destroy]

  # GET /teams
  # GET /teams.json
  def index
    @teams = Team.all
  end


  # GET /teams/1
  # GET /teams/1.json
  def show
  end

  # GET /teams/new
  def new
    @team = Team.new
  end

  # GET /teams/1/edit
  def edit
  end

  # POST /teams
  # POST /teams.json
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

  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
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

  # DELETE /teams/1
  # DELETE /teams/1.json
  def destroy
    @team.destroy
    respond_to do |format|
      format.html { redirect_to teams_url, notice: 'Team was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def remove_membership

    @team = TeamMembership.find(params[:id]) rescue nil
    @project_admin = TeamMembership.where("team_id = ? AND state = ?", @team.team_id, 'admin').collect(&:team_member_id) rescue nil
    @task=Task.find(@team.id)
    if (current_user.id == @team.task.project.user.id && @team.destroy)
      @notice='Team member  was successfully Removed.'
    else
      if (@project_admin.include? current_user.id)
        if @team.state == "admin"
          @notice='You can\'t remove admin.'
        else
          if @team.destroy
            @notice='Team member  was successfully Removed.'
          else
            @notice="You can't remove Team Member"
          end
        end
      end
    end
    respond_to do |format|
      puts @notice
      format.html { redirect_to teams_url, notice: @notice }
      format.json { head :no_content }
      format.js
    end

  end

  # POST /team_memberships
  # POST /team_memberships.json
  def team_memberships
    @project = Project.find(params[:project_id])
    @team = @project.team
    if @team.nil?
      @project_team = @project.create_team(name: "Team#{project.id}", mission: "More rock and roll", slots: 10)
      @project_team.save
      first_member = TeamMembership.create(team_member_id: @project.user_id, team_id: @project_team.id)
      first_member.save
    end
    @project_team = Team.where(project_id: @project.id).first
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
      format.html { redirect_to :back }
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
