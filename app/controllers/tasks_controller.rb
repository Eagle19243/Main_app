class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy, :accept, :reject, :doing, :task_fund_info, :removeMember, :refund]
  before_action :validate_user, only: [:accept, :reject, :doing]
  before_action :validate_team_member, only: [:reviewing]
  before_action :validate_admin, only: [:completed]
  protect_from_forgery :except => :update
  before_action :authenticate_user!, only: [:send_email, :create, :new, :edit, :destroy, :accept, :reject, :doing, :reviewing, :completed]


  def validate_team_member
    @task= Task.find(params[:id]) rescue nil
    @task_memberships = @task.team_memberships
    if !(@task.doing? && (@task_memberships.collect(&:team_member_id).include? current_user.id))
      @notice = " you are not allowed to do this opration "
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
        @notice = " you are not allowed to do this opration "
        respond_to do |format|
          format.js
          format.html { redirect_to task_path(@task.id), notice: @notice }
        end
      end
    end
  end

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

  # GET /tasks/new
  def new
    @project = Project.find(params[:project_id])
    @task = @project.tasks.build
  end

  # GET /tasks/1/edit
  def edit
    @project = Task.find(params[:id]).project
  end

  # POST /tasks
  # POST /tasks.json
  def create
    project = Project.find(params[:task][:project_id])

    authorize! :create, project.tasks.new(state: params[:task][:state])

    service = TaskCreateService.new(create_task_params, current_user, project)

    respond_to do |format|
      redirect_path = taskstab_project_path(project, tab: 'Tasks')

      if service.create_task
        format.html { redirect_to redirect_path, notice: 'Task was successfully created.' }
        format.json { render :show, status: :created, location: service.task }
      else
        format.html { redirect_to redirect_path, alert: "Task was not created" }
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

        format.html { redirect_to @task, notice: 'Task was successfully updated.' }
        format.json { render :show, status: :ok, location: @task }
        format.js
      else
        format.html { render :edit }
        format.json { render json: @task.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.json
  def destroy
    authorize! :destroy, @task

    service = TaskDestroyService.new(@task, current_user)

    respond_to do |format|
      redirect_path = taskstab_project_path(@task.project, tab: 'Tasks')

      if service.destroy_task
        format.html { redirect_to redirect_path, notice: 'Task was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to redirect_path, alert: 'Error happened while task delete process' }
        format.json { head :no_content }
      end
    end
  end

  def refund
    if current_user.id == @task.project.user_id
      bitgo_fee = 0.10
      access_token = Payments::BTC::Base.bitgo_access_token
      @wallet_address = @task.wallet_address
      api = Bitgo::V1::Api.new
      response = api.get_wallet(wallet_id: @wallet_address.wallet_id, access_token: access_token)
      @task.update_attribute('current_fund', response["balance"]) rescue nil
      if @task.current_fund > 0
        funded_by_stripe = @task.stripe_payments
        funded_from_user_wallets = UserWalletTransaction.where(user_wallet: @task.wallet_address.sender_address)
        @task.stripe_refund(funded_by_stripe, bitgo_fee)
        @task.user_wallet_refund(funded_from_user_wallets, bitgo_fee)
        funded_by_stripe.destroy_all
        funded_from_user_wallets.destroy_all
        flash[:notice] = "Successfull refund the task "
        response = api.get_wallet(wallet_id: @wallet_address.wallet_id, access_token: access_token)
        @task.update_attribute('current_fund', response["balance"]) rescue nil
      else
        flash[:notice] = "Can't Refund Task it has 0 BTC"
      end
    else
      flash[:notice] = "Not authorized to refund this task"
    end
    redirect_to task_path(@task)
  end

  def accept
    if !@task.accepted? && @task.accept!
      @notice = "Task accepted "
      NotificationMailer.accept_task(@task.user, @task).deliver_later
      NotificationsService.notify_about_accept_task(@task, @task.user)
    else
      @notice = "Task was not accepted"
    end
    respond_to do |format|
      format.js
      format.html { redirect_to taskstab_project_path(@task.project, tab: 'Tasks'), notice: @notice }
    end
  end

  def doing

    authorize! :doing, @task

    if @task.suggested_task?
      @notice = "You can't Do this Task"
    else
      if @task.not_fully_funded_or_less_teammembers?
        @notice = "Number of team Members less than Required Number of Team Members or Current Fund is Less Than Actual Budget"
      else
        # if (current_user.id == @task.project.user_id || @task.is_executer(current_user.id)) && @task.start_doing!
        if @task.start_doing!
          @notice = "Task Status changed to Doing "
        else
          @notice = "Error in Moving Task"
        end
      end
    end
    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), notice: @notice }
    end
  end

  def reject
    if @task.reject!
      flash[:notice] = "Task #{@task.title} has been rejected"
      NotificationsService.notify_about_rejected_task(@task) if current_user == @task.project.user
      @task.destroy
    else
      flash[:notice] = "Task was not rejected"
    end

    respond_to do |format|
      format.js
      format.html { redirect_to taskstab_project_path(@task.project, tab: 'Tasks'), notice: @notice }
    end

  end

  def reviewing

    authorize! :reviewing, @task

    if current_user.can_submit_task?(@task) && @task.begin_review!
      @notice = "Task Submitted for Review"
    else
      @notice = "Task Was Not  Submitted for Review"
    end

    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), notice: @notice }
    end
  end

  def completed
    authorize! :completed, @task

    service = TaskCompleteService.new(@task)
    service.complete!

    @notice = "Task was successfully completed"

    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), notice: @notice }
    end
  rescue ArgumentError, Payments::BTC::Errors::TransferError => error
    ErrorHandlerService.call(error)
    @notice = error.message

    respond_to do |format|
      format.js
      format.html { redirect_to task_path(@task.id), alert: @notice }
    end
  end

  def send_email
    InvitationMailer.invite_user(params['email'], current_user.name, Task.find(params['task_id'])).deliver_later
    flash[:success] = "Task link has been send to #{params[:email]}"
    redirect_to task_path(params['task_id'])
  end

  def removeMember
    @team_membership = TeamMembership.find(params[:team_membership_id])
    respond_to do |format|
      if @task.team_memberships.destroy(@team_membership)
        format.json { render json: @team_membership.id, status: :ok }
      else
        format.json { render status: :internal_server_error }
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_task
    @task = Task.find(params[:id]) rescue nil
  end

  def validate_user
    unless current_user.is_project_leader?(@task.project) || current_user.is_executor_for?(@task.project)
      flash[:error] = "You are Not authorized  to do this operation "
      redirect_to taskstab_project_path(@task.project_id)
    end
  end

  def create_task_params
    params.require(:task).permit(default_attributes)
  end

  def update_task_params
    attributes = default_attributes
    attributes.delete(:deadline) if @task.any_fundings?

    params.require(:task).permit(attributes)
  end

  def default_attributes
    %i(references deadline target_number_of_participants
       short_description number_of_participants proof_of_execution title
       description budget user_id condition_of_execution fileone filetwo
       filethree filefour filefive state)
  end
end
