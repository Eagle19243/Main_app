class ProjectsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :saveEdit, :updateEdit]
  before_action :set_project, only: [:show, :edit, :update, :destroy, :saveEdit, :updateEdit, :htmlshow]
  before_action :get_project_user, only: [:show, :htmlshow]
  autocomplete :projects, :title, :full => true
  autocomplete :users, :name, :full => true
  autocomplete :tasks, :title, :full => true
  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.all
  end

  def autocomplete_user_search
    term = params[:term]
    @projects = Project.order(:title).where("title LIKE ? or description LIKE ?", "%#{params[:term]}%","%#{params[:term]}%").map{|p|"#{p.title}"}
    @result = @projects + Task.order(:title).where("title LIKE ? or description LIKE ?", "%#{params[:term]}%","%#{params[:term]}%").map{|t|"#{t.title}"}
    #@projects = @projects + User.order(:name).where("name LIKE ?", "%#{params[:term]}%").map{|user|"#{user.name}"}
      respond_to do |format|
      format.html {render text: @result}
      format.json { render json: @result.to_json,status: :ok}
      end
  end
  # GET /notifications
  def htmlindex
  test  @projects = Project.all
  end

  def user_search
    #User search has been disabled because we don't have user's public profile or show page yet available in application we will just add Sunspot.search(Project,Task,User) later
    @search = Sunspot.search(Task,Project) do
      fulltext params[:title] do
        query_phrase_slop 1
      end
    end
    @results = @search.results
    unless @results.blank?
      respond_to do |format|
       format.html {render  :search_results}
      end
    else
      redirect_to root_path ,alert: 'sorry no results match with your search'
    end
  end

  def search_results
    #display solar search results
  end


  # GET /notifications
  def htmlshow
    @comments = @project.project_comments.all
    @proj_admins_ids = @project.proj_admins.ids
    @current_user_id = 0
    if user_signed_in?
      @current_user_id = current_user.id
    end

  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @comments = @project.project_comments.all
    @proj_admins_ids = @project.proj_admins.ids
    @current_user_id = 0
    if user_signed_in?
      @current_user_id = current_user.id
    end

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
    if @project.user.admin?
      @project.state = "accepted"
    else
      @project.state = "pending"
    end

    respond_to do |format|
      if @project.save
        activity = current_user.create_activity(@project, 'created')
        activity.user_id = current_user.id
        format.html { redirect_to @project, notice: 'Project request was sent.' }
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

  # POST /save-edits
  # POST /save-edits.json
  def saveEdit
    @project_edit = @project.project_edits.create(description: edit_params[:project_edit])
    @project_edit.user = current_user
    puts @project_edit.description
    respond_to do |format|
      if @project_edit.save
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end

  end


  # POST /update-edits
  # POST /update-edits.json
  def updateEdit
    id_t = params[:project][:editItem][:id]
    new_state = params[:project][:editItem][:new_state]
    puts "id_t: " + id_t
    @project_edit = ProjectEdit.find_by(id: id_t)
    @project_edit.update(:aasm_state => new_state)
    puts @project_edit.description
    if new_state == "accepted"
      @project.description = @project_edit.description

      respond_to do |format|
        if @project.save
          format.html { redirect_to @project, notice: 'Project was successfully updated.' }
          format.json { render json: @project, status: :ok }
        else
          format.html { render :edit }
          format.json { rende
r json: @project.errors, status: :unprocessable_entity }
        end
      end
    end

    if new_state == "rejected"
      respond_to do |format|
        if @project.save
          format.html { redirect_to @project, notice: 'Project was successfully updated.' }
          format.json { render json: @project, status: :ok }
        else
          format.html { rende
r :edit }
          format.json { render json: @project.errors, status: :unprocessable_entity }
        end
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

    redirect_to current_user

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
    redirect_to current_user

  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      activity = current_user.create_activity(@project, 'deleted')
      activity.user_id = current_user.id
      format.html { redirect_to dashboard_path, notice: 'Project was successfully destroyed.' }
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
      params.require(:project).permit(:title, :short_description, :institution_country, :description, :country, :picture, :user_id, :institution_location, :state, :expires_at, :request_description, :institution_name, :institution_logo, :institution_description,
        project_edits_attributes: [:id, :_destroy, :description])
    end

    def get_project_user
      set_project
      @project_user = @project.user
    end

    def edit_params
      params.require(:project).permit(:id, :project_edit, :editItem)
    end
end
