module Pusher
  class AuthController < ApplicationController
    def create
      uuid = params[:channel_name].gsub(/^private-/, '')
      chat_session = ChatSession.find_by_uuid(uuid)
      if current_user && chat_session &&
         chat_session.participating_user?(current_user)
        response = Pusher.authenticate(params[:channel_name],
                                       params[:socket_id])
        render json: response, status: :created
      else
        render json: 'Forbidden', status: :forbidden
      end
    end
  end
end
