class TasksController < ApplicationController
  before_action :set_task, only: [:show, :update, :destroy, :accept, :reject, :doing, :task_fund_info, :remove_member, :refund, :incomplete]
  before_action :validate_user, only: [:accept, :doing, :incomplete]
  before_action :validate_team_member, only: [:reviewing]
  before_action :validate_admin, only: [:completed]
  protect_from_forgery :except => :update
  before_action :authenticate_user!, only: [:send_email, :create, :destroy, :accept, :reject, :doing, :reviewing, :completed, :incomplete]

  def show
   # @task = Task.find(params[:id])
    @project = @task.project
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
    @tasks_count =tasks.count
    @sourcing_tasks = tasks.where(state: ["pending", "accepted"]).all
    @done_tasks = tasks.where(state: "completed").count

    @contents, @subpages, @is_blocked = @project.page_info(current_user)

    @histories = get_revision_histories @project

    @mediawiki_api_base_url = Project.load_mediawiki_api_base_url

    @apply_requests = @project.apply_requests.pending.all
    @task_comments = @task.task_comments
    @task_attachment = TaskAttachment.new
    @task_attachments = @task.task_attachments
    @task_memberships = @task.team_memberships
    task_comment_ids = @task.task_comments.collect(&:id)
    @activities = Activity.where("(targetable_type= ? AND targetable_id=?) OR (targetable_type= ? AND targetable_id IN (?))", "Task", @task.id, "TaskComment", task_comment_ids).order('created_at DESC')
  #  project_admin
  #  redirect_to taskstab_project_path(@task.project.id)
  end

  # POST /tasks
  # POST /tasks.json
  def create
    project = Project.find(params[:task][:project_id])

    authorize! :create, project.tasks.new(state: params[:task][:state])

    service = TaskCreateService.new(create_task_params, current_user, project)

    respond_to do |format|
      redirect_path = taskstab_project_path(project, tab: 'tasks')

      if service.create_task
        format.html { redirect_to redirect_path, notice: t('.notice_message') }
        format.json { render :show, status: :created, location: service.task }
      else
        format.html { redirect_to redirect_path, alert: t('.alert_message') }
        format.json { render json: service.task.errors, status: :unprocessable_entity }
      end
    end
  end

  def task_fund_info
    respond_to do |format|
       format.json { render json: { balance: Payments::BTC::Converter.convert_satoshi_to_btc(@task.current_fund), task_id: @task.id, project_id: @task.project_id , status: 200} }
    end
  end

  # PATCH/PUT /tasks/1
  # PATCH/PUT /tasks/1.json
  def update
    authorize! :update, @task

    respond_to do |format|
      @task_memberships = @task.team_memberships

      if @task.update(update_task_params)
        current_user.create_activity(@task, 'edited')

        format.html { render nothing: true }
        format.json { render :show, status: :ok, location: @task }
        format.js
      else
        format.html { render nothing: true }
        format.json { render json: @task.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  def destroy
    authorize! :destroy, @task
    begin
      service = TaskDestroyService.new(@task, current_user)
      redirect_path = taskstab_project_path(@task.project, tab: 'tasks')

      if service.destroy_task
        flash[:notice] = t('.notice_message')
      else
        flash[:error] = t('.error_message')
      end
    rescue Payments::BTC::Errors::GeneralError => error
      ErrorHandlerService.call(error)
      flash[:error] = UserErrorPresenter.new(error).message
    end
    respond_to do |format|
      format.js   { head :no_content }
      format.html { redirect_to redirect_path }
    end
  end

  def refund
    raise NotImplementedError, t('.refunds_disabled')
  end

  def accept
    authorize! :accept, @task

    if @task.accept!
      @notice = t('.task_accepted')
      # the user that suggested the task might not be a follower neither a team_member
      (@task.project.interested_users + [@task.user]).uniq.each do |user|
        NotificationMailer.accept_new_task(task: @task, receiver: user).deliver_later
      end
      NotificationsService.notify_about_accept_task(@task, @task.user)
    else
      @notice = t('.task_not_accepted')
    end
    respond_to do |format|
      format.js
      format.html { redirect_to taskstab_project_url(@task.project, tab: 'tasks'), notice: @notice }
    end
  end

  def doing
    authorize! :doing, @task

    if @task.suggested_task?
      flash[:alert] = t('.cannot_do')
    else
      if @task.not_fully_funded_or_less_teammembers?
        flash[:alert] = t('.goal_not_meet')
      else
        # if (current_user.id == @task.project.user_id || @task.is_executer(current_user.id)) && @task.start_doing!
        if @task.start_doing!
          @task.project.interested_users.each do |user|
            NotificationMailer.task_started(acting_user: current_user, task: @task, receiver: user).deliver_later
          end
          flash[:notice] =  t('.task_changed_to_doing')
        else
          flash[:alert] = t('.error_moving')
        end
      end
    end
    respond_to do |format|
      format.js
      format.html { redirect_to taskstab_project_path(@task.project, tab: 'tasks') }
    end
  end

  def reject
    authorize! :reject, @task
    current_state_of_task = @task.state

    if @task.reject! && @task.destroy
      flash[:notice] = t('.task_rejected', task_title: @task.title)
      NotificationsService.notify_about_rejected_task(@task) if current_user == @task.project.user

      if current_state_of_task == 'suggested_task'
        (@task.project.interested_users - [@task.user]).each do |user|
          NotificationMailer.notify_others_for_rejecting_new_task(task_title: @task.title, project: @task.project, receiver: user).deliver_later
        end

        NotificationMailer.notify_user_for_rejecting_new_task(task_title: @task.title, project: @task.project, receiver: @task.user).deliver_later
      else
        @task.project.interested_users.each do |user|
          NotificationMailer.task_deleted(task_title: @task.title, project: @task.project, receiver: user, admin: current_user).deliver_later
        end
      end
    else
      flash[:error] = t('.task_not_rejected')
    end

    respond_to do |format|
      format.js
      format.html { redirect_to taskstab_project_url(@task.project, tab: 'tasks') }
    end
  end

  def reviewing
    authorize! :reviewing, @task

    if current_user.can_submit_task?(@task) && @task.begin_review!
      @notice = t('.task_submitted')
      @task.project.interested_users.each do |user|
        NotificationMailer.under_review_task(reviewee: current_user, task: @task, receiver: user).deliver_later
      end
    else
      @notice = t('.task_not_sumitted')
    end

    respond_to do |format|
      format.js
      format.html { redirect_to taskstab_project_path(@task.project, tab: 'tasks'), notice: @notice }
    end
  end

  def completed
    authorize! :completed, @task

    service = TaskCompleteService.new(@task)
    service.complete!

    @notice = t('.task_completed')

    @task.project.interested_users.each do |user|
      NotificationMailer.task_completed(receiver: user, task: @task, reviewer: current_user).deliver_later
    end

    respond_to do |format|
      format.js
      format.html { redirect_to taskstab_project_path(@task.project, tab: 'tasks'), notice: @notice }
    end
  rescue ArgumentError, Payments::BTC::Errors::GeneralError => error
    ErrorHandlerService.call(error)
    @notice = UserErrorPresenter.new(error).message

    respond_to do |format|
      format.js
      format.html { redirect_to taskstab_project_path(@task.project, tab: 'tasks'), notice: @notice }
    end
  end

  def incomplete
    authorize! :incomplete, @task

    @task.incomplete!
    @task.project.interested_users.each do |user|
      NotificationMailer.task_incomplete(reviewer: current_user, task: @task, receiver: user).deliver_later
    end
    task_incomplete_activity = Activity.new(
      user: current_user,
      action: "incomplete",
      targetable_id: @task.id,
      targetable_type: "Task"
      )
    task_incomplete_activity.save!
    redirect_to taskstab_project_path(@task.project, tab: 'tasks'), notice: t('.task_incompleted', task_title: @task.title, project_title: @task.project.title)
  end

  def send_email
    InvitationMailer.invite_user(params['email'], current_user.display_name, Task.find(params['task_id'])).deliver_later
    @notice = t('.task_link_sent', email: params[:email])
    respond_to :js
  end

  def remove_member
    authorize! :remove_member, @task

    @team_membership = @task.team_memberships.find(params[:team_membership_id])

    respond_to do |format|
      TeamMembership.transaction do
        begin
          # Must give reason to remove a member
          if params[:reason]
            assignee = @team_membership.team_member

            @team_membership.update!(deleted_reason: params[:reason])
            @team_membership.destroy!

            current_user.create_activity(@team_membership, 'deleted')
            NotificationMailer.notify_assignee_on_removing_from_task(assignee, @task).deliver_later

            @task.project.interested_users.each do |user|
              NotificationMailer.notify_interested_user_on_removing_from_task(assignee, user, @task).deliver_later
            end

            flash[:notice] = t('.success')
            format.json { render json: @team_membership.id, status: :ok }
          else
            flash[:error] = t('.fail')
            format.json { render json: @team_membership.errors, status: :unprocessable_entity }
          end
        rescue
          format.json { render json: @team_membership.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_task
    @task = Task.find(params[:id]) rescue nil
  end

  def validate_user
    unless current_user.is_project_leader?(@task.project) || current_user.is_coordinator_for?(@task.project)
      flash[:error] = t('controllers.unauthorized_message')
      redirect_to taskstab_project_path(@task.project_id)
    end
  end

  def create_task_params
    params.require(:task).permit(default_attributes)
  end

  def update_task_params
    attributes = default_attributes
    attributes.delete(:deadline) if cannot? :update_deadline, @task
    attributes.delete(:budget)   if cannot? :update_budget, @task
    attributes.delete(:free)     if cannot? :update_budget, @task

    result_hash = params.require(:task).permit(attributes)
    if result_hash["free"]
      result_hash["free"] = (result_hash["free"] == 'true')
      result_hash["budget"] = Payments::BTC::Converter.convert_satoshi_to_btc(Task::MINIMUM_FUND_BUDGET) unless result_hash["free"]
    end
    result_hash
  end

  def default_attributes
    %i(references project_id deadline target_number_of_participants
       short_description number_of_participants proof_of_execution title
       description budget user_id condition_of_execution fileone filetwo
       filethree filefour filefive state free)
  end

  def validate_team_member
    @task= Task.find(params[:id]) rescue nil
    @task_memberships = @task.team_memberships
    if !(@task.doing? && (@task_memberships.collect(&:team_member_id).include? current_user.id))
      @notice = t('.not_allowed')
      respond_to do |format|
        format.js
        format.html { redirect_to task_path(@task.id), notice: @notice }
      end
    end
  end

  def validate_admin
    @task = Task.find(params[:id]) rescue nil
    if @task.blank?
      redirect_to '/'
    else
      if !(current_user.id == @task.project.user_id && @task.reviewing?)
        @notice = t('.not_allowed')
        respond_to do |format|
          format.js
          format.html { redirect_to task_path(@task.id), notice: @notice }
        end
      end
    end
  end

  def get_revision_histories(project)
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
end
