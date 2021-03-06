class RequestMailer < ApplicationMailer
  def apply_to_get_involved_in_project(applicant:, project:, request_type:)
    @applicant = applicant
    @leader = project.leader
    @project = project
    @request_type = request_type

    mail(to: @leader.email, subject: t('.subject', request_type: @request_type) )
  end

  def positive_response_in_project_involvement(apply_request:)
    set_instance_variables_for_project_involvement(apply_request)

    mail(to: @applicant.email, subject: t('.subject', request_type: @request_type))
  end

  def negative_response_in_project_involvement(apply_request:)
    set_instance_variables_for_project_involvement(apply_request)

    mail(to: @applicant.email, subject: t('.subject', request_type: @request_type))
  end

  def to_do_task(requester:, task:)
    @requester = requester
    @task = task
    leader = @task.project.user

    mail(to: leader.email, subject: t('.subject'))
  end

  def accept_to_do_task(do_request:)
    set_instance_variables_for_to_do_review(do_request)

    mail(to: @requester.email, subject: t('.subject'))
  end

  def reject_to_do_task(do_request:)
    set_instance_variables_for_to_do_review(do_request)

    mail(to: @requester.email, subject: t('.subject'))
  end

  private

  def set_instance_variables_for_to_do_review(do_request)
    @task = do_request.task
    @requester = do_request.user
  end

  def set_instance_variables_for_project_involvement(apply_request)
    @applicant = apply_request.user
    @request_type = apply_request.request_type.try(:gsub, '_', ' ')
    @project = apply_request.project
  end
end
