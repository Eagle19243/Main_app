class NotificationsController < ApplicationController
  before_action :set_notification, only: [:show, :edit, :update, :destroy]
  layout false , only: [:index]
  # GET /notifications
  # GET /notifications.json


    def index
        @notifications = Notification.all
        #@task = Task.all
        #@users = User.all
        if current_user.admin == true
          @array=Project.where(:state => 'pending')
        else
          @array_tasks = Array.new
          @pendding_do_request = Array.new
          @array_projects=Project.where(:user_id => current_user.id)
            @array_projects.each do|d|
              @array_tasks.concat d.tasks.where(:state => 'suggested_task')

            end
        end


        current_user.projects.each do |p|
           all_project_tasks_ids << p.tasks.collect(&:id)
         end
        all_project_tasks_ids.flatten
       # @pendding_do_request=DoRequest.where(task_id: all_project_taks_ids AND state:'pending' )
        @pendding_do_request=DoRequest.where( "task_id = ? AND status = ?", all_project_tasks_ids, 'Pending')



        @pro=Project.find(params["format"]) rescue nil
        @tsk=Task.find(params["format"]) rescue nil

     end

  # GET /notifications
  def htmlindex
    @notifications = Notification.all
  end

  # GET /notifications/1
  # GET /notifications/1.json
  def show
  end

  # GET /notifications/new
  def new
    @notification = Notification.new
  end

  # GET /notifications/1/edit
  def edit
  end

  # POST /notifications
  # POST /notifications.json
  def create
    @notification = Notification.new(notification_params)

    respond_to do |format|
      if @notification.save
        format.html { redirect_to @notification, notice: 'Notification was successfully created.' }
        format.json { render :show, status: :created, location: @notification }
      else
        format.html { render :new }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notifications/1
  # PATCH/PUT /notifications/1.json
  def update
    respond_to do |format|
      if @notification.update(notification_params)
        format.html { redirect_to @notification, notice: 'Notification was successfully updated.' }
        format.json { render :show, status: :ok, location: @notification }
      else
        format.html { render :edit }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/1
  # DELETE /notifications/1.json
  def destroy
    @notification.destroy
    respond_to do |format|
      format.html { redirect_to notifications_url, notice: 'Notification was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notification
      @notification = Notification.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def notification_params
      params.require(:notification).permit(:type, :summary, :content)
    end
end
