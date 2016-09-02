class InstitutionUsersController < ApplicationController
  before_action :set_institution_user, only: [:show, :edit, :update, :destroy]

  # GET /institution_users
  # GET /institution_users.json
  def index
    @institution_users = InstitutionUser.all
  end

  # GET /institution_users/1
  # GET /institution_users/1.json
  def show
  end

  # GET /institution_users/new
  def new
    @institution_user = InstitutionUser.new
  end

  # GET /institution_users/1/edit
  def edit
  end

  # POST /institution_users
  # POST /institution_users.json
  def create
    @institution_user = InstitutionUser.new(institution_user_params)

    respond_to do |format|
      if @institution_user.save
        format.html { redirect_to @institution_user, notice: 'Institution user was successfully created.' }
        format.json { render :show, status: :created, location: @institution_user }
      else
        format.html { render :new }
        format.json { render json: @institution_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /institution_users/1
  # PATCH/PUT /institution_users/1.json
  def update
    respond_to do |format|
      if @institution_user.update(institution_user_params)
        format.html { redirect_to @institution_user, notice: 'Institution user was successfully updated.' }
        format.json { render :show, status: :ok, location: @institution_user }
      else
        format.html { render :edit }
        format.json { render json: @institution_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /institution_users/1
  # DELETE /institution_users/1.json
  def destroy
    @institution_user.destroy
    respond_to do |format|
      format.html { redirect_to institution_users_url, notice: 'Institution user was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_institution_user
      @institution_user = InstitutionUser.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def institution_user_params
      params.require(:institution_user).permit(:institution_id, :user_id, :position)
    end
end
