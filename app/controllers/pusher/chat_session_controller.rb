module Pusher
  class ChatSessionController < ApplicationController
    def create
      chat_session = ChatSession.new(chat_session_params)
      chat_session.requester = current_user
      if chat_session.save
        ChatMailer.invite_receiver(requester.id, receiver.id).deliver_later
        render json: chat_session.uuid, status: :created
      else
        render json: chat_session.errors.full_messages,
               status: :unprocessable_entity
      end
    end

    def update
      chat_session = ChatSession.find_by_uuid(params[:uuid])
      if chat_session.update(status: :finished)
        render json: chat_session.uuid, status: :ok
      else
        render json: chat_session.errors.full_messages,
               status: :unprocessable_entity
      end
    end

    private

    def chat_session_params
      params.require(:chat_session).permit(:receiver_id)
    end
  end
end
