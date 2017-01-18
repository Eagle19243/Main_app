class ApplyRequestsController < ApplicationController
  load_and_authorize_resource
  before_action :set_apply_request, only: [:accept, :reject]

  def accept
    @apply_request = ApplyRequest.find(params[:id])
    @apply_request.accept!

    if @apply_request.request_type == "Lead_Editor"
      project = @apply_request.project
      user    = @apply_request.user

      project.grant_permissions user.username
    end

    role = @apply_request.request_type == "Lead_Editor"? TeamMembership.roles[:lead_editor] : TeamMembership.roles[:executor]

    TeamService.add_team_member(@apply_request.project.team, @apply_request.user, role)

    redirect_to :my_projects

  end

  def reject
    @apply_request = ApplyRequest.find(params[:id])
    @apply_request.reject!
    redirect_to :my_projects
  end

  private
  def set_apply_request
    @apply_request = ApplyRequest.find(params[:id])
  end

end
