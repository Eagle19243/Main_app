class GroupmessagesController < ApplicationController
  # layout false
  before_action :authenticate_user!
  before_action :set_groupmessage, only: [:show, :edit, :update, :destroy]

  # GET /groupmessages
  # GET /groupmessages.json
  def index
    @groupmessages = Groupmessage.all
    @new_message = @groupmessages
    @groupmessage = Groupmessage.new

  end

  # GET /groupmessages/1
  # GET /groupmessages/1.json
  def show
  end

  # GET /groupmessages/new
  def new
    @groupmessage = Groupmessage.new
  end

  # GET /groupmessages/1/edit
  def edit
  end

  # POST /groupmessages
  # POST /groupmessages.json
  def create
    @groupmessage = Groupmessage.new(groupmessage_params)

    respond_to do |format|
      if @groupmessage.save
        format.html { redirect_to @groupmessage, notice: 'Groupmessage was successfully created.' }
        format.json { render :show, status: :created, location: @groupmessage }
      else
        format.html { render :new }
        format.json { render json: @groupmessage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groupmessages/1
  # PATCH/PUT /groupmessages/1.json
  def update
    respond_to do |format|
      if @groupmessage.update(groupmessage_params)
        format.html { redirect_to @groupmessage, notice: 'Groupmessage was successfully updated.' }
        format.json { render :show, status: :ok, location: @groupmessage }
      else
        format.html { render :edit }
        format.json { render json: @groupmessage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groupmessages/1
  # DELETE /groupmessages/1.json
  def destroy
    @groupmessage.destroy
    respond_to do |format|
      format.html { redirect_to groupmessages_url, notice: 'Groupmessage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_groupmessage
      @groupmessage = Groupmessage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def groupmessage_params
      params.require(:groupmessage).permit(:messgae, :Groupmember_id, :Chatroom_id, :Project_id)
    end
end
