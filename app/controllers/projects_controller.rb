class ProjectsController < ApplicationController

  load_and_authorize_resource :except => [:get_activities, :show_all_revision, :show_all_teams, :show_all_tasks, :project_admin, :send_project_email, :show_task, :send_project_invite_email, :contacts_callback, :read_from_mediawiki, :write_to_mediawiki, :revision_action, :revisions, :start_project_by_signup, :taskstab, :failure, :get_in, :block_user, :unblock_user, :plan, :switch_approval_status]

  autocomplete :projects, :title, :full => true
  autocomplete :users, :name, :full => true
  autocomplete :tasks, :title, :full => true
  before_action :set_project, only: [:show, :show_all_teams, :show_all_tasks, :taskstab, :show_project_team, :edit, :update, :destroy, :saveEdit, :updateEdit, :follow, :rate, :discussions, :read_from_mediawiki, :write_to_mediawiki, :revision_action, :revisions, :show_all_revision, :block_user, :unblock_user, :plan, :switch_approval_status]
  before_action :get_project_user, only: [:show, :taskstab, :show_project_team]
  skip_before_action :verify_authenticity_token, only: [:rate]
  before_filter :authenticate_user!, only: [:contacts_callback]

  # skip_authorization_check []
  before_action :set_gon

  def set_gon
    @short_descr_limit = gon.short_descr_limit = Project::SHORT_DESCRIPTION_LIMIT
  end

  def index
    if user_signed_in?
      if current_user.user_wallet_address.blank?
        current_user.assign_address
      end
    end
    #Every Time someone visits home page it ittrate N times Thats not a good approch .
    # Project.all.each { |project| project.create_team(name: "Team #{project.id}") unless !project.team.nil? }
    @featured_projects = Project.where.not(state: "rejected").page params[:page]

    if session[:start_by_signup]
      if session[:start_by_signup] == "true"
        @start_project = true
      elsif session[:start_by_signup] == "false"
        @start_project = false
      end
      session[:start_by_signup] = ''
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def original_url
    request.base_url + request.original_fullpath
  end

  def send_project_invite_email
    session[:success_contacts] = nil
    @array = params[:emails].split(',')
    @array.each do |key|
      InvitationMailer.invite_user_for_project(key, current_user.name, Project.find(session[:idd]).title, session[:idd]).deliver_now
    end
    session[:success_contacts] = "Project link has been shared  successfully with your friends!"
    session[:project_id] = session[:idd]
    session[:email] = "email-success"
    redirect_to controller: 'projects', action: 'taskstab', id: session[:idd]
  end

  def send_project_email
    respond_to do |format|
      unless params['email'].blank?
        if current_user.blank?
          @notice = "ERROR: Please sign in to continue."
          format.js {}
        else
          begin
            InvitationMailer.invite_user_for_project(params['email'], current_user.name,
                                                     Project.find(params['project_id']).title, params['project_id']).deliver_later
            format.html { redirect_to controller: 'projects', action: 'taskstab', id: params['project_id'], notice: "Project link has been sent to #{params[:email]}" }
            @notice = "Project link has been sent to #{params[:email]}"
            format.js {}
          rescue => e
            @notice = "Error ".concat e.inspect
            format.js {}
          end

        end
      else
        session[:project_id] = session[:idd]
        format.html { redirect_to controller: 'projects', action: 'taskstab', id: params['project_id'], notice: "Please provide receiver email." }
        @notice = 'Please provide receiver email.'
        format.js {}
      end
    end
  end

  def contacts_callback
    @contacts = request.env['omnicontacts.contacts']
    respond_to do |format|
      format.html
    end
  end

  def failure
    session[:failure_contacts] = nil
    session[:project_id] = session[:idd]
    session[:email_failure] = "failure_email"
    redirect_to controller: 'projects', action: 'taskstab', id: session[:idd]
    session[:failure_contacts] = "No, Project invitation Email was sent to your Friends!"
  end

  def show_task
    @task = Task.find(params[:id])
    @task_comments = @task.task_comments
    @task_attachment = TaskAttachment.new
    @task_attachments = @task.task_attachments
    @task_memberships = @task.team_memberships
    task_comment_ids = @task.task_comments.collect(&:id)
    @activities = Activity.where("(targetable_type= ? AND targetable_id=?) OR (targetable_type= ? AND targetable_id IN (?))", "Task", @task.id, "TaskComment", task_comment_ids).order('created_at DESC')
    project_admin
    respond_to :js
  end

  def autocomplete_user_search
    results = []
    if params[:term].present?
      projects = Project.fulltext_search(params[:term]).map(&:title)
      tasks = Task.fulltext_search(params[:term]).map(&:title)

      results = [projects, tasks].flatten
    end
    respond_to do |format|
      format.html { render text: results }
      format.json { render json: results.to_json, status: :ok }
    end
  end

  def user_search
    #User search has been disabled because we don't have user's public profile or show page yet available in application we will just add Sunspot.search(Project,Task,User) later
    @results = []

    if params[:title].present?
      # TODO I think here we should have 2 objects projects and tasks, not 1 single result object
      projects = Project.fulltext_search(params[:title])
      tasks = Task.fulltext_search(params[:title])
      @results = [projects, tasks].flatten
    end
    unless @results.blank?
      respond_to do |format|
        # format.html {render  :search_results}
        format.js
      end
    else
      respond_to do |format|
        format.js
        # format.html {render  :search_results ,alert: 'Sorry no results match with your search'}
      end
    end
  end

  def search_results
    #display solar search results
  end

  def project_admin
    @project_admin = TeamMembership.where("team_id = ? AND state = ?", @task.project.team.id, 'admin').collect(&:team_member_id) rescue nil
  end

  def show
    redirect_to taskstab_project_path(@project.id)
  end

  def archived
    @featured_projects = Project.only_deleted.page params[:page]
    respond_to do |format|
      format.html
      format.js
    end
  end

  def follow
    redirect_to @project and return if current_user.id == @project.user_id
    if params[:follow] == 'true'
      flash[:alert] = follow_project.errors.full_messages.to_sentence unless @project.follow!(current_user)
    else
      current_user.followed_projects.delete @project
    end
    redirect_to @project
  end

  def unfollow
    project = Project.find params[:id]
    project.unfollow!(current_user)
    flash[:notice] = "You stopped following project " + project.title
    redirect_to :my_projects
  end

  def rate
    @rate = @project.project_rates.find_or_create_by(user_id: current_user.id)
    @rate.rate = params[:rate]
    @rate.save
    render json: {
        rate: @rate,
        average: @project.rate_avg
    }
  end

  def get_activities
    @task=Task.find(params[:id])
    task_comment_ids = @task.task_comments.collect(&:id)
    @activities = Activity.where("(targetable_type= ? AND targetable_id=?) OR (targetable_type= ? AND targetable_id IN (?))", "Task", @task.id, "TaskComment", task_comment_ids).order('created_at DESC').limit(30)
    respond_to :js
  end

  # GET /projects/1/taskstab
  def taskstab
    if session[:email] == "email-success"
      flash[:notice] = "Project link has been shared  successfully with your friends!"
      flash.discard(:notice)
      session[:email] = nil
    end

    if session[:email_failure] == "failure_email"
      flash[:notice] = "No, Project invitation Email was sent to your Friends!"
      flash.discard(:notice)
      session[:email_failure] = nil
    end

    @available_credit_cards = Payments::StripeSources.new.call(user: current_user) if current_user
    @comments = @project.project_comments.all
    @proj_admins_ids = @project.proj_admins.ids
    @current_user_id = 0
    @followed = false
    @rate = 0

    if user_signed_in?
      @followed = @project.project_users.pluck(:user_id).include? current_user.id
      @current_user_id = current_user.id
      @rate = @project.project_rates.find_by(user_id: @current_user_id).try(:rate).to_i
    end

    tasks = @project.tasks.all
    @tasks_count = tasks.size
    @team_memberships_count = @project.team_memberships_count
    @contents = ''
    @is_blocked = 0

    if current_user
      result = @project.page_read current_user.username
    else
      result = @project.page_read nil
    end

    if result
      if result["status"] == 'success'
        @contents = result["html"]
        @is_blocked = result["is_blocked"]
      end
    end

    @histories = get_revision_histories @project
    # if approved_versions?(@histories) == 0
    #   @contents = ''
    # end

    @mediawiki_api_base_url = Project.load_mediawiki_api_base_url

    @apply_requests = @project.apply_requests.pending.all
    @change_leader_invitation = @project.change_leader_invitations.where(:new_leader => current_user.email).first if current_user && @project.change_leader_invitations.where(:new_leader => current_user.email).present?
  end

  def revisions
    authorize! :revisions, @project

    @histories = get_revision_histories @project
    @mediawiki_api_base_url = Project.load_mediawiki_api_base_url

    respond_to do |format|
      format.js
    end
  end

  def switch_approval_status

    authorize! :switch_approval_status, @project

    @histories = get_revision_histories @project
    @mediawiki_api_base_url = Project.load_mediawiki_api_base_url

    if params[:is_approval_enabled].present?
      @project.update_attribute(:is_approval_enabled, params[:is_approval_enabled])

      if @project.is_approval_enabled?
        # Approve latest revision
        @project.approve_revision @histories[0]["revision_id"]
      else
        # Unapprove approved revisions
        @project.unapprove
      end

      @histories = get_revision_histories @project
    end

    respond_to do |format|
      format.js
    end
  end

  def plan
    tasks = @project.tasks.all
    @tasks_count =tasks.count
    @sourcing_tasks = tasks.where(state: ["pending", "accepted"]).all
    @mediawiki_api_base_url = Project.load_mediawiki_api_base_url

    @contents = ''
    @is_blocked = 0
    if current_user
      result = @project.page_read current_user.username
    else
      result = @project.page_read nil
    end
    if result
      if result["status"] == 'success'
        @contents = result["html"]
        @is_blocked = result["is_blocked"]
      end
    end

    # @histories = get_revision_histories @project
    # if approved_versions?(@histories) == 0
    #   @contents = ''
    # end

    @apply_requests = @project.apply_requests.pending.all

    respond_to do |format|
      format.js
    end
  end

  def revision_action

    authorize! :revision_action, @project

    if params[:type] == 'approve'
      @project.approve_revision params[:rev]
    elsif params[:type] == 'unapprove'
      @project.unapprove_revision params[:rev]
    end

    redirect_to taskstab_project_path(@project.id)
  end

  def block_user

    authorize! :block_user, @project

    @project.block_user params[:username]
    redirect_to taskstab_project_path(@project.id)
  end

  def unblock_user

    authorize! :unblock_user, @project

    @project.unblock_user params[:username]
    redirect_to taskstab_project_path(@project.id)
  end

  def show_project_team
    respond_to do |format|
      format.js
    end
  end

  def show_all_tasks
    tasks = @project.tasks.all
    @tasks_count =tasks.count
    @sourcing_tasks = tasks.where(state: ["pending", "accepted"]).all
    @doing_tasks = tasks.where(state: "doing").all
    @suggested_tasks = tasks.where(state: "suggested_task").all
    @reviewing_tasks = tasks.where(state: "reviewing").all
    @done_tasks = tasks.where(state: "completed").all
    respond_to do |format|
      format.js
    end
  end

  def show_all_teams
    respond_to do |format|
      format.js
    end
  end

  def show_all_revision
    @histories = get_revision_histories @project

    respond_to do |format|
      format.js
    end
  end

  def new
    @project = Project.new
  end

  def edit

  end

  def create
    @project = current_user.projects.build(project_params)
    @project.user_id = current_user.id
    if @project.user.admin?
      @project.state = "accepted"
    else
      @project.state = "pending"
    end

    @project.wiki_page_name = filter_page_name @project.title

    respond_to do |format|
      if @project.save
        if current_user.username
          # Create new page in wiki and this user will be the owner of this wiki page and project
          @project.page_write current_user, ''
        end

        @project_team = @project.create_team(name: "Team#{@project.id}")
        TeamMembership.create(team_member_id: current_user.id, team_id: @project_team.id,role:1 )
        activity = current_user.create_activity(@project, 'created')
        # activity.user_id = current_user.id
        chatroom =Chatroom.create(name: @project.title, project_id: @project.id)
        Groupmember.create(user_id: current_user.id, chatroom_id: chatroom.id)
        format.html { redirect_to @project, notice: 'Project request was sent.' }
        format.json { render json: {id: @project.id, status: 200, responseText: "Project has been Created Successfully "} }
        session[:project_id] = @project.id
      else
        Rails.logger.debug "Failed to save new project #{@project}"
        format.html { render :new }
        format.json { render json: @project.errors.full_messages.to_sentence, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      old_name = @project.wiki_page_name
      @project.wiki_page_name = filter_page_name project_params["title"] if project_params["title"].present?
      if @project.update(project_params)
        if old_name != @project.wiki_page_name
          @project.rename_page current_user.username, old_name
        end
        activity = current_user.create_activity(@project, 'updated')
        activity.user_id = current_user.id
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render :json => @project.errors.full_messages, :status =>:unprocessable_entity }
        format.json {respond_with_bip(@project)}
      end
    end
  end

  def change_leader
    @project = Project.find params[:project_id]
    @email = params[:leader]["address"]
    @new_leader = User.where(email: @email).present? ? User.where(email: @email).first : nil

    if @project.change_leader_invitations.pending.any?
      flash[:notice] = "You have already invited a new leader for this project."
    elsif @new_leader == nil
      flash[:error] = "Can't find the user who have the email address you entered. Please input valid email address."
    elsif !(@project.team.team_memberships.pluck(:team_member_id).include? @new_leader)
      @invitation = @project.change_leader_invitations.create(new_leader: @email, sent_at: Time.current)
      flash[:notice] = "The user is not team memeber of the project. You can only invite team member as a new leader."
    elsif @email != current_user.email
      @invitation = @project.change_leader_invitations.create(new_leader: @email, sent_at: Time.current)
      InvitationMailer.invite_leader(@invitation.id).deliver_now
      NotificationsService.notify_about_change_leader_invitation(current_user, @new_leader, @project)
      flash[:notice] = "You sent an invitation for leader role to " + @email
    end

    redirect_to :my_projects
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
          format.json { render json: @project.errors, status: :unprocessable_entity }
        end
      end
    end

    if new_state == "rejected"
      respond_to do |format|
        if @project.save
          format.html { redirect_to @project, notice: 'Project was successfully updated.' }
          format.json { render json: @project, status: :ok }
        else
          format.html { render :edit }
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
      @project.user.update_attribute(:role, 'manager')
      #Change all pending projects for user
      flash[:notice] = "Project Request accepted"
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

  def get_in
    type = params[:type]
    request_type = type=="1" ? "Lead_Editor" : "Executor"
    project = Project.find(params[:id])
    if type==1 && current_user.is_lead_editor_for?(project)
      flash[:notice] = "You are already Lead Editor of this project."
    elsif type==2 && current_user.is_executor_for?(project)
      flash[:notice] = "You are already excutor of this project."
    elsif current_user.has_pending_apply_requests?(project, request_type)
      flash[:notice] = "You have submitted this request already."
    else
      ApplyRequest.create( user_id: current_user.id,project_id: project.id, request_type: request_type)
      flash[:notice] = "Your request has been submitted"
    end

    redirect_to project
  end

  def read_from_mediawiki

    @contents = ''
    @mediawiki_api_base_url = Project.load_mediawiki_api_base_url

    if params[:rev]
      @revision_id = params[:rev]
      result = @project.get_revision params[:rev]
      if result
        @contents = result["content"]
      end
    else
      # Get Latest Revision editable
      result = @project.get_latest_revision
      @contents = ''
      if result
        @contents = result
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def write_to_mediawiki
    if @project.page_write current_user, params[:data]
      result = @project.page_read nil
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    authorize! :destroy, @project

    @project.destroy
    respond_to do |format|
      activity = current_user.create_activity(@project, 'deleted')
      activity.user_id = current_user.id
      format.html { redirect_to :my_projects, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def start_project_by_signup
    session[:start_by_signup] = params[:start_by_signup]
    render json: {
        status: true
    }
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_project
    if user_signed_in? && current_user.admin?
      @project = Project.with_deleted.find(params[:id])
    else
      @project = Project.find(params[:id])
    end

  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def project_params
    params.require(:project).permit(
        :title, :short_description, :institution_country, :description, :country,
        :picture, :user_id, :institution_location, :state, :expires_at, :request_description,
        :institution_name, :institution_logo, :institution_description, :section1, :section2,
        :picture_crop_x, :picture_crop_y, :picture_crop_w, :picture_crop_h,
        project_edits_attributes: [:id, :_destroy, :description]
    )
  end

  def get_project_user
    @project_user = @project.user
  end

  def edit_params
    params.require(:project).permit(:id, :project_edit, :editItem)
  end

  # Get revision histories
  def get_revision_histories project
    result = project.get_history
    @histories = []

    if result
      result.each do |r|
        history                = Hash.new
        history["revision_id"] = r["id"]
        history["datetime"]    = DateTime.strptime(r["timestamp"],"%s").strftime("%l:%M %p %^b %d, %Y")
        history["user"]        = User.find_by_username(r["author"][0].downcase+r["author"][1..-1]) || User.find_by_username(r["author"])
        history["status"]      = r['status']
        history["comment"]     = r['comment']
        history["username"]    = r["author"]
        history["is_blocked"]  = r["is_blocked"]

        @histories.push(history)
      end
      return @histories
    else
      return []
    end
  end

  # Get status if there are approved versions or not
  def approved_versions? histories
    flg = 0

    histories.each do |history|
      if history["status"] == "approved"
        flg = 1
        break
      end
    end

    return flg
  end

  # Fitler wiki page name regarding page title
  def filter_page_name title
    title.gsub("&", " ").gsub("#", " ").gsub("[", " ").gsub("]", " ").gsub("|", " ").gsub("{", " ").gsub("}", " ").gsub("<", " ").gsub(">", " ").strip
  end
end
