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
    if project.chatroom.present?
      Groupmember.create(user: user, chatroom: project.chatroom)
    end
  end

  def self.remove_user_from_project_chatroom(project,user)
    if project.chatroom.present?
      users_groupmember = project.chatroom.groupmembers.where(user: user).first
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
      "#{self.user.name} to #{self.recipient.name}"
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
