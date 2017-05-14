class PaymentMailer < ApplicationMailer
  def fund_task(payer:, task:, receiver:, amount:)
    @receiver = receiver
    @task = task
    @amount = amount
    @payer = payer

    mail(to: @receiver.email, subject: t('.subject'))
  end

  def fully_funded_task(task:, receiver:)
    @receiver = receiver
    @task = task

    mail(to: @receiver.email, subject: t('.subject'))
  end
end
