class Ability
  include CanCan::Ability

  def initialize(user)
    initializeProjectsPermissions(user)
    initializeUsersPermissions(user)
    initializeMessagesPermissions(user)
    initializeProfileCommentsPermissions(user)
    initializeProjAdminPermissions(user)
    initializeTasksPermissions(user)
    initializeAdminInvitationsPermissions(user)
    initializeAdminRequestsPermissions(user)
    initializeApplyRequestsPermissions(user)
    initializeTeamMembershipsPermissions(user)
  end

  def initializeTeamMembershipsPermissions(user)
    if user
      can [:update], TeamMembership do |team_membership|
        team_membership.team.project.user.id == user.id && user.is_project_leader?(team_membership.team.project)
      end
    end
  end

  def initializeAdminInvitationsPermissions(user)
    if user
      can [:create], AdminInvitation do |admin_invitation|
        admin_invitation.sender.id == user.id
      end
      can [:accept, :reject], AdminInvitation, :user_id => user.id
    end
  end

  def initializeAdminRequestsPermissions(user)
    if user
      can [:create], AdminRequest
      can [:accept, :reject], AdminRequest do |admin_request|
        admin_request.project.user.id == user.id
      end
    end
  end

  def initializeApplyRequestsPermissions(user)
    if user
      can [:create], ApplyRequest
      can [:accept, :reject], ApplyRequest do |apply_request|
        apply_request.project.user.id == user.id
      end
    end
  end

  def initializeProjectsPermissions(user)
    can [:read, :search_results, :user_search, :autocomplete_user_search, :taskstab, :show_project_team, :invite_admin, :get_in], Project
    if user
      can [:create, :discussions, :follow, :unfollow, :rate, :accept_change_leader, :reject_change_leader, :my_projects], Project
      can [:update, :change_leader], Project do |project|
        user.is_admin_for?(project)
      end
      can :archived, Project if user.admin?
      can :destroy, Project, :user_id => user.id
    end
  end

  def initializeUsersPermissions(user)
    can :show, User
    if user
      can [:my_projects], User
      can [:update, :destroy], User, :id => user.id
      if user.admin
        can :index, User
      end
    end
  end

  def initializeMessagesPermissions(user)
    if user
      can :manage, GroupMessage
    end
  end

  def initializeProfileCommentsPermissions(user)
    can :read, ProfileComment
    if user
      can :create, ProfileComment
      can [:destroy, :update], ProfileComment, :commenter_id => user.id
    end
  end

  def initializeProjAdminPermissions(user)
    if user
      can [:create, :destroy, :update], ProjAdmin do |proj_admin|
        proj_admin.project.user.id == user.id
      end
    end
  end

  def initializeTasksPermissions(user)
    can :read, Task
    if user
      can :create, Task
      can [:update, :destroy], Task do |task|
        user.is_admin_for?(task.project)
      end

      if user.admin?
        can [:update, :destroy], Task
      end
    end
  end
end
