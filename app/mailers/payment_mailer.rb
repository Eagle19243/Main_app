class PaymentMailer < ApplicationMailer
  def fund_task(payer:, task:, receiver:, amount:)
    @receiver = receiver
    @task = task
    @amount = amount
    @payer = payer

    mail(to: @receiver.email, subject: I18n.t('mailers.payment.fund_task.subject'))
  end
end
