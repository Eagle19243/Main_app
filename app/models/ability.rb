class Ability
  include CanCan::Ability

  def initialize(user)
    initializeProjectsPermissions(user)
    initializeUsersPermissions(user)
    initializeMessagesPermissions(user)
    initializeProfileCommentsPermissions(user)
  end

  def initializeProjectsPermissions(user)
    can [:read, :search_results, :user_search, :autocomplete_user_search], Project
    if user
      can [:create, :discussions, :follow, :rate, :tasktab, :teamtab], Project
      
      can :update, Project do |project|
        user.is_admin_for?(project) 
      end

      can :destroy, Project, :user_id => user.id
      
      if user.admin? 
        #here goes what only admin can do
      end
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
end
