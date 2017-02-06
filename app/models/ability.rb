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
    initializeTaskCommentsPermissions(user)
    initializeTaskAttachmentsPermissions(user)
  end

  def initializeTeamMembershipsPermissions(user)
    if user

      can [:create, :update], TeamMembership do |team_membership|
        user.is_project_leader?(team_membership.team.project)
      end

      can [:destroy], TeamMembership do |team_membership|
        user.is_project_leader?(team_membership.team.project) && team_membership.team_member != user
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
      can [:update, :change_leader, :accept, :reject ], Project do |project|
        user.is_project_leader?(project)
      end
      can [:revisions, :revision_action, :block_user, :unblock_user, :switch_approval_status], Project do |project|
        user.is_project_leader?(project) || user.is_lead_editor_for?(project)
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
        task.suggested_task?
      end

      can :create, Task do |task|
        task.accepted? && (user.is_project_leader?(task.project) || user.is_executor_for?(task.project))
      end

      can [:update, :destroy], Task do |task|
        (user.is_project_leader?(task.project) || user.is_executor_for?(task.project) || (task.suggested_task? && (user.id == task.user_id))) && (task.any_fundings? == false)
      end

      can :reviewing, Task do |task|
        user.can_submit_task?(task)
      end

      can :completed, Task do |task|
        user.can_complete_task?(task)
      end

      can :doing, Task do |task|
        task.accepted? && user.is_teammember_for?(task)
      end

      can :create_task_comment, Task do |task|
        user.is_teammember_for?(task)
      end

      can :create_or_destory_task_attachment, Task do |task|
        user.is_project_leader?(task.project) || user.is_executor_for?(task.project) || (task.team_memberships.collect(&:team_member_id).include? user.id) || (task.suggested_task? && (user.id == task.user_id))
      end

      if user.admin?
        can [:create, :update, :destroy], Task
      end
    end
  end

  def initializeTaskCommentsPermissions(user)
    if user
      can :create, TaskComment do |task_comment|
        user.is_teammember_for?(task_comment.task)
      end
    end
  end

  def initializeTaskAttachmentsPermissions(user)
    if user
      can [:create, :destroy], TaskAttachment do |task_attachment|
        user.is_project_leader?(task_attachment.task.project) || user.is_executor_for?(task_attachment.task.project) || (task_attachment.task.team_memberships.collect(&:team_member_id).include? user.id) || (task_attachment.task.suggested_task? && (user.id == task_attachment.task.user_id))
      end
    end
  end
end
