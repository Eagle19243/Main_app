class PaymentMailer < ApplicationMailer
  def fund_task(payer:, task:, receiver:, amount:)
    @receiver = receiver
    @task = task
    @amount = amount
    @payer = payer

    mail(to: @receiver.email, subject: I18n.t('mailers.payment.fund_task.subject'))
  end

  def fully_funded_task(task:, receiver:)
    @receiver = receiver
    @task = task

    mail(to: @receiver.email, subject: I18n.t('mailers.payment.fully_funded_task.subject'))
  end
end
