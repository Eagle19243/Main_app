class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.all
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @comments = @project.project_comments.all
  end

  # GET /projects/new
  def new
    @project = Project.new
   
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = current_user.projects.build(project_params)
    @project.user_id = current_user.id
    if @project.user.admin? || @project.user.manager?
      @project.state = "accepted"
    else
      @project.state = "pending"
    end

    respond_to do |format|
      if @project.save  
        activity = current_user.create_activity(@project, 'created')
        activity.user_id = current_user.id
        format.html { redirect_to @project, notice: 'Project was created.' }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        activity = current_user.create_activity(@project, 'updated')
        activity.user_id = current_user.id
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end




  def accept
    @project = Project.find(params[:id])
     if @project.accept!
       activity = current_user.create_activity(@project, 'accepted')
       activity.user_id = current_user.id
        @project.user.update_attribute(:role, 'manager');
        #Change all pending projects for user
      flash[:success] = "Project Request accepted"
    else
      flash[:error] = "Project could not be accepted"
    end

    redirect_to page_path('dashboard')

  end



  def reject
    @project = Project.find(params[:id])
    if @project.reject!
      activity = current_user.create_activity(@project, 'rejected')
      activity.user_id = current_user.id
      flash[:success] = "Project rejected"
    else
      flash[:error] = "Project could not be rejected"
    end
    redirect_to page_path('dashboard')

  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      activity = current_user.create_activity(@project, 'deleted')
      activity.user_id = current_user.id
      format.html { redirect_to projects_url, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(:title, :description, :country, :picture, :user_id, :institution_location, :state, :expires_at, :request_description, :institution_name, :institution_logo, :institution_description)
    end
end
