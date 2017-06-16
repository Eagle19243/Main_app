class Pusher::AuthController < ApplicationController
  def create
    if current_user
      response = Pusher.authenticate(params[:channel_name], params[:socket_id])
      render json: response
    else
      render text: 'Forbidden', status: '403'
    end
  end
end
