include UsersHelper
include ApplicationHelper

class UsersController < ApplicationController
  load_and_authorize_resource :except => [:index,:my_wallet]
  layout "dashboard", only: [:my_projects]

  def index
    authorize! :index, current_user
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @profile_comments = @user.profile_comments.limit(3)
  end

  def my_projects
    @user = current_user
  end

  def update
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update_attributes(update_params)
        format.html { 
          current_user.create_activity(@user, 'updated')
          redirect_to(@user, :notice => 'User was successfully updated.')
        }
        format.json { respond_with_bip(@user) }
      else
        redirect_to users_path, :alert => "Unable to update user."
        format.json { respond_with_bip(@user) }
      end
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    current_user.create_activities(@user, 'deleted')
    redirect_to users_path, :notice => "User deleted."
  end

  def my_wallet
    access_token = access_wallet
    @wallet_address = current_user.user_wallet_address
    api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
    response = api.get_wallet(wallet_id:@wallet_address.wallet_id, access_token: access_token)
    @wallet_address.update_attribute('current_balance',response["balance"]) rescue nil
    @transactions = api.list_wallet_transctions(@wallet_address.sender_address, access_token) rescue nil
  end

  private

  def update_params
    params.require(:user).permit(:picture, :name, :email, :password, :bio,
    :city, :phone_number, :bio, :facebook_url, :twitter_url,
    :picture_crop_x, :picture_crop_y, :picture_crop_w, :picture_crop_h,
    :linkedin_url, :picture_cache)
  end

  def secure_params
    params.require(:user).permit(:role, :picture, :name, :email, :password, :bio,
    :city, :phone_number, :bio, :facebook_url, :twitter_url,
    :linkedin_url, :picture_cache)
  end

end
