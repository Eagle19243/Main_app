class Ability
  include CanCan::Ability

  def initialize(user)
    initializeProjectsPermissions(user)
    initializeUsersPermissions(user)
    initializeMessagesPermissions(user)
    initializeProfileCommentsPermissions(user)
    initializeProjAdminPermissions(user)
    initializeTasksPermissions(user)
  end

  def initializeProjectsPermissions(user)
    can [:read, :search_results, :user_search, :autocomplete_user_search, :taskstab, :show_project_team, :invite_admin], Project
    if user
      can [:create, :discussions, :follow, :rate], Project     
      can :update, Project do |project|
        user.is_admin_for?(project) 
      end
      can :destroy, Project, :user_id => user.id
    end
  end

  def initializeUsersPermissions(user)
    can :read, User
    if user
      can [:my_projects], User
      can [:update, :destroy], User, :id => user.id 
    end
  end

  def initializeMessagesPermissions(user)
    if user
      can :manage, Message
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