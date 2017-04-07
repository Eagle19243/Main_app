class ProjectRequestsService
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def requests_count
    pending_do_requests.count + pending_apply_requests.count
  end

  def pending_do_requests
    DoRequest.pending.where(project_id: @project.id)
  end

  def pending_apply_requests
    ApplyRequest.pending.where(project_id: @project.id)
  end
end
