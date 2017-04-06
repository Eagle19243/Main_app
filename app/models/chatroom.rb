class Chatroom < ActiveRecord::Base

#-------------------------------------------------------------------------------
# Associations
#-------------------------------------------------------------------------------

  belongs_to :project
  belongs_to :user
  belongs_to :recipient, foreign_key: "recipient_id", class_name: "User"
  has_many :groupmembers, dependent: :destroy
  has_many :group_messages, dependent: :destroy

#-------------------------------------------------------------------------------
# Class Methods
#-------------------------------------------------------------------------------

  def self.add_user_to_project_chatroom(project,user)
    project_chatroom = project.get_project_chatroom
    project_chatroom.groupmembers.create(user_id: user.id) if project_chatroom.present?
  end

  def self.remove_user_from_project_chatroom(project,user)
    project_chatroom = project.get_project_chatroom
    if project_chatroom.present?
      users_groupmember = project_chatroom.groupmembers.where(user: user).first
      users_groupmember.destroy if users_groupmember.present?
    end
  end

  def self.create_direct_chatroom(current_user,recipient_user)
    Chatroom.create(user: current_user, recipient: recipient_user)
  end

  def self.create_team_member_direct_chatroom(project,current_user,recipient_user)
    Chatroom.create(project: project, user: current_user, recipient: recipient_user)
  end

  def self.validate_access_from_params(chatroom_id,current_user)
    chatroom = Chatroom.find(chatroom_id)
    if chatroom.present?
      if chatroom.project.present? && chatroom.user.blank? && chatroom.recipient.blank?
        #Project Group Chatroom
        (chatroom.groupmembers & current_user.groupmembers).any?
      elsif chatroom.user.present? && chatroom.recipient.present?
        #Direct Message to a Project Team Member or Direct Message with no Project
        [chatroom.user,chatroom.recipient].include?(current_user)
      end
    end
  end

  def self.get_project_chatroom_team_members_group_messages(project,current_user)
    chatroom = project.chatrooms.where(user: nil, recipient: nil).first
    if chatroom.present? && chatroom.validate_access_for(current_user)
      team_members = chatroom.groupmembers.where.not(user: current_user)
      group_messages = chatroom.group_messages
    end
    
    return chatroom, team_members, group_messages
  end
  
  def self.get_or_create_project_dm_chatroom_group_messages(project,current_user,recipient_user)
    chatroom = (current_user.chatrooms.where(project: project, recipient: recipient_user) + current_user.chatrooms_where_recipient.where(project: project, user: recipient_user)).first
    if chatroom.present?
      group_messages = chatroom.group_messages
    else
      if current_user.is_team_member_for?(project)
        chatroom = Chatroom.create_team_member_direct_chatroom(project,current_user,recipient_user)
        group_messages = []
      end
    end
    
    return chatroom, group_messages
  end
  
  def self.get_or_create_dm_chatroom_group_messages(current_user,recipient_user)
    chatroom = (current_user.chatrooms.where(project: nil, recipient: recipient_user) + current_user.chatrooms_where_recipient.where(project: nil, user: recipient_user)).first
    if chatroom.present?
      group_messages = chatroom.group_messages
    else
      chatroom = Chatroom.create_direct_chatroom(current_user,recipient_user)
      group_messages = []
    end
    
    return chatroom, group_messages
  end
  
#-------------------------------------------------------------------------------
# Instance Methods
#-------------------------------------------------------------------------------

  def get_display_title
    if self.project.present? && !self.recipient.present?
      #Project Group Chatroom
      self.project.title
    elsif self.project.present? && self.user.present? && self.recipient.present?
      #Direct Message to a Project Team Member
      "#{self.project.title} - #{self.user.name} to #{self.recipient.name}"
    elsif !self.project.present? && self.user.present? && self.recipient.present?
      #Direct Message with no Project
      "Messages from #{self.recipient.name}"
    end
  end

  def validate_access_for(current_user)
    if self.project.present? && self.user.blank? && self.recipient.blank?
      #Project Group Chatroom
      (self.groupmembers & current_user.groupmembers).any?
    elsif self.user.present? && self.recipient.present?
      #Direct Message to a Project Team Member or Direct Message with no Project
      [self.user,self.recipient].include?(current_user)
    end
  end

#-------------------------------------------------------------------------------

end
