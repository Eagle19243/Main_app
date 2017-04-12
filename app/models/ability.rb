class Ability
  include CanCan::Ability

  def initialize(user)
    initializeProjectsPermissions(user)
    initializeUsersPermissions(user)
    initializeMessagesPermissions(user)
    initializeProfileCommentsPermissions(user)
    initializeProjAdminPermissions(user)
    initializeTasksPermissions(user)
    initializeAdminRequestsPermissions(user)
    initializeApplyRequestsPermissions(user)
    initializeDoRequestsPermissions(user)
    initializeTeamMembershipsPermissions(user)
    initializeTaskAttachmentsPermissions(user)
  end

  def initializeTeamMembershipsPermissions(user)
    if user

      can [:create, :update], TeamMembership do |team_membership|
        user.is_project_leader?(team_membership.team.project)
      end

      can [:destroy], TeamMembership do |team_membership|
        (user.is_project_leader?(team_membership.team.project) && team_membership.team_member != user) || (user.is_coordinator_for?(team_membership.team.project) && team_membership.role == 'teammate')
      end

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
      can [:accept, :reject], ApplyRequest do |apply_request|
        can :manage_requests, apply_request.project
      end
    end
  end

  def initializeDoRequestsPermissions(user)
    if user
      can [:accept, :reject], DoRequest do |do_request|
        can :manage_requests, do_request.project
      end
    end
  end

  def initializeProjectsPermissions(user)
    can [:read, :search_results, :user_search, :autocomplete_user_search, :taskstab, :show_project_team, :get_in], Project
    if user
      can [:create, :discussions, :follow, :unfollow, :rate, :accept_change_leader, :reject_change_leader, :my_projects], Project
      can [:update, :change_leader, :accept, :reject ], Project do |project|
        user.is_project_leader?(project)
      end
      can [:revisions, :revision_action, :block_user, :unblock_user, :switch_approval_status], Project do |project|
        user.is_project_leader?(project) || user.is_lead_editor_for?(project)
      end
      can :manage_requests, Project do |project|
        user.is_project_leader?(project) || user.is_coordinator_for?(project)
      end
      can :archived, Project if user.admin?
      can :destroy, Project, :user_id => user.id
    end
  end

  def initializeUsersPermissions(user)
    can :show, User
    if user
      can [:my_projects], User
      can [:update, :destroy, :my_wallet], User, :id => user.id
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

      can :create, Task do |task|
        (task.suggested_task? && !user.is_project_leader_or_coordinator?(task.project)) ||
        (task.accepted? && user.is_project_leader_or_coordinator?(task.project))
      end

      can :update, Task do |task|
        ((task.suggested_task? || task.accepted?) && user.is_project_leader_or_coordinator?(task.project)) ||
        (task.suggested_task? && (user.id == task.user_id))
      end

      can [:update_budget, :update_deadline, :destroy], Task do |task|
        !task.any_fundings? && can?(:update, task)
      end

      can :reviewing, Task do |task|
        user.can_submit_task?(task)
      end

      can :completed, Task do |task|
        task.reviewing? && (user.is_project_leader_or_coordinator?(task.project))
      end

      can :doing, Task do |task|
        task.accepted? && user.is_teammember_for?(task)
      end

      can :create_task_comment, Task do
        true
      end

      can :create_or_destory_task_attachment, Task do |task|
        user.is_project_leader?(task.project) || user.is_coordinator_for?(task.project) || (task.team_memberships.collect(&:team_member_id).include? user.id) || (task.suggested_task? && (user.id == task.user_id))
      end

      if user.admin?
        can [:create], Task
      end
    end
  end

  def initializeTaskAttachmentsPermissions(user)
    if user
      can [:create, :destroy], TaskAttachment do |task_attachment|
        user.is_project_leader?(task_attachment.task.project) || user.is_coordinator_for?(task_attachment.task.project) || (task_attachment.task.team_memberships.collect(&:team_member_id).include? user.id) || (task_attachment.task.suggested_task? && (user.id == task_attachment.task.user_id))
      end
    end
  end
end
