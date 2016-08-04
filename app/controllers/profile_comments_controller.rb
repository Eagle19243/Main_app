class ProfileCommentsController < ApplicationController
  before_action :set_profile_comment, only: [:show, :edit, :update, :destroy]

  # GET /profile_comments
  # GET /profile_comments.json
  def index
    @profile_comments = ProfileComment.all
  end

  # GET /profile_comments/1
  # GET /profile_comments/1.json
  def show
  end

  # GET /profile_comments/new
  def new
    @profile_comment = ProfileComment.new
  end

  # GET /profile_comments/1/edit
  def edit
  end

  # POST /profile_comments
  # POST /profile_comments.json
  def create
    @profile_comment = ProfileComment.new(profile_comment_params)

    respond_to do |format|
      if @profile_comment.save
        format.html { redirect_to @profile_comment, notice: 'Profile comment was successfully created.' }
        format.json { render :show, status: :created, location: @profile_comment }
      else
        format.html { render :new }
        format.json { render json: @profile_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /profile_comments/1
  # PATCH/PUT /profile_comments/1.json
  def update
    respond_to do |format|
      if @profile_comment.update(profile_comment_params)
        format.html { redirect_to @profile_comment, notice: 'Profile comment was successfully updated.' }
        format.json { render :show, status: :ok, location: @profile_comment }
      else
        format.html { render :edit }
        format.json { render json: @profile_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profile_comments/1
  # DELETE /profile_comments/1.json
  def destroy
    @profile_comment.destroy
    respond_to do |format|
      format.html { redirect_to profile_comments_url, notice: 'Profile comment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_profile_comment
      @profile_comment = ProfileComment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def profile_comment_params
      params.require(:profile_comment).permit(:commenter_id, :receiver_id, :comment_text)
    end
end
