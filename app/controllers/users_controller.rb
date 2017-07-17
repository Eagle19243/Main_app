class UsersController < ApplicationController
  load_and_authorize_resource :except => [:index]
  layout "dashboard", only: [:my_projects]

  def index
    authorize! :index, current_user
    @users = User.all
  end

  def show
    @user = User.not_hidden.find(params[:id])
    @profile_comments = @user.profile_comments.limit(3)
  end

  def my_projects
    @user = current_user
  end

  def update
    @user = User.find(params[:id])

    @user.attributes = update_params
    if @user.invalid?
      if @user.errors.messages.include?(:background_picture) || @user.errors.messages.include?(:picture)
        message = t('.file_type_fail', allowed_types: PictureUploader::SUPPORTED_PICTURE_EXTENSIONS.join(', '))
      else
        message = t('.fail')
      end
      respond_to do |format|
        flash[:error] = message
        format.js { render json: { alert: message }, status: 422 }
        format.html { redirect_to @user }
      end
    else
      @user.save
      current_user.create_activity(@user, 'updated')
      respond_to do |format|
        format.js { render json: true, status: 201 }
        format.html { render :show }
      end
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    current_user.create_activities(@user, 'deleted')
    redirect_to users_path, notice: t('.success')
  end

  def my_wallet
    @wallet = current_user.wallet

    if @wallet
      @transactions = wallet_handler.get_wallet_transactions(@wallet.wallet_id)
      @receiver_address = @wallet.receiver_address

      @wallet_balance = wallet_handler.get_wallet_balance(@wallet.wallet_id)
      @wallet.update(balance: @wallet_balance)
    else
      @transactions = []
      @wallet_balance = 0.0
    end
  rescue Payments::BTC::Errors::GeneralError => error
    ErrorHandlerService.call(error)
    flash[:error] = UserErrorPresenter.new(error).message
    redirect_to root_path
  end

  private

  def update_params
    allowed = [:first_name, :last_name, :picture, :password, :bio, :city,
               :state, :phone_number, :bio, :facebook_url, :twitter_url,
               :skype_id, :facebook_id, :linkedin_id, :twitter_id,
               :picture_crop_x, :picture_crop_y, :picture_crop_w,
               :picture_crop_h, :linkedin_url, :picture_cache,
               :background_picture, :preferred_language]
    allowed << :email if current_user.email.blank?
    params.require(:user).permit(*allowed)
  end

  def secure_params
    params.require(:user).permit(:role, :picture, :name, :email, :password, :bio,
    :city, :phone_number, :bio, :facebook_url, :twitter_url,
    :linkedin_url, :picture_cache)
  end

end
