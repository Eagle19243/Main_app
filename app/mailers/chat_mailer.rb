class ChatMailer < ApplicationMailer
  def invite_receiver(requester_id, receiver_id)
    @requester = User.find(requester_id)
    @receiver = User.find(receiver_id)
    mail(to: @receiver.email,
         subject: t('.subject', requester_name: @requester.display_name))
  end
end
