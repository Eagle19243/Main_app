class User < ActiveRecord::Base
  enum role: [:user, :vip, :admin, :manager, :moderator]
  after_initialize :set_default_role, :if => :new_record?

  searchable do
    text :name
  end

  def set_default_role
    self.role ||= :user
  end
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  mount_uploader :picture, PictureUploader
  after_create :populate_guid_and_token

  has_many :projects, dependent: :destroy
  has_many :project_edits, dependent: :destroy
  has_many :project_comments, dependent: :delete_all
  has_many :activities, dependent: :delete_all
  has_many :do_requests, dependent: :delete_all
  has_many :do_for_frees
  has_many :assignments, dependent: :delete_all
  has_many :donations
  has_many :proj_admins, dependent: :delete_all

  # users can send each other profile comments
  has_many :profile_comments, foreign_key: "receiver_id", dependent: :destroy
  has_many :project_rates
  has_many :team_memberships, foreign_key: "team_member_id"
  has_many :teams, :through => :team_memberships
  has_many :conversations, foreign_key: "sender_id"
  has_many :project_users
  has_many :followed_projects, through: :project_users, class_name: 'Project', source: :project
  has_many :discussions, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :admin_requests, dependent: :destroy

  def self.current_user
    Thread.current[:current_user]
  end

  def self.current_user=(usr)
    Thread.current[:current_user] = usr
  end

  def create_activity(item, action)
    activity = activities.new
    activity.targetable = item
    activity.action = action
    activity.save
    activity
  end

  def assign(taskItem, booleanFree)
    assignment = assignments.new
    assignment.task = taskItem
    assignment.project_id= assignment.task.project_id
    assignment.free = booleanFree
    assignment.save
    assignment.accept!
    assignment
  end

  def location
    [city, country].compact.join(' / ')
  end

  def completed_tasks_count
    assignments.completed.count
  end

  def funded_projects_count
    donations.joins(:task).pluck('tasks.project_id').uniq.count
  end

  def populate_guid_and_token
    random = SecureRandom.uuid()
    arbitraryAuthPayload = { :uid => random,:auth_data => random, :other_auth_data => self.created_at.to_s}
    generator = Firebase::FirebaseTokenGenerator.new("ZWx3jy7jaz8IuPXjJ8VNlOMlOMGFEIj0aHNE7tMt")
    random2 = generator.create_token(arbitraryAuthPayload)
    self.guid = random
    self.chat_token = random2
    self.save
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    if user
      return user
    else
      registered_user = User.where(:email => auth.info.email).first
      if registered_user
        return registered_user
      else
        user = User.create(
            provider:auth.provider,
            uid:auth.uid,
            name:auth.info.name,
            email:auth.info.email,
            password:Devise.friendly_token[0,20],
        )
      end    end
  end

  def self.find_for_twitter_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    if user
      return user
    else
      registered_user = User.where(:email => auth.uid + "@twitter.com").first
      if registered_user
        return registered_user
      else

        user = User.create(
            provider:auth.provider,
            uid:auth.uid,
            name:auth.info.name,
            email:auth.uid+"@twitter.com",
            password:Devise.friendly_token[0,20],
        )
      end

    end
  end

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:provider => access_token.provider, :uid => access_token.uid ).first
    if user
      return user
    else
      registered_user = User.where(:email => access_token.info.email).first
      if registered_user
        return registered_user
      else
        user = User.create(
            provider:access_token.provider,
            email: data["email"],
            uid: access_token.uid ,
            name: access_token.info.name,
            password: Devise.friendly_token[0,20],
        )
      end
    end
  end

  def is_admin_for? proj
    proj.user_id == self.id || proj_admins.where(project_id: proj.id).exists?
  end

  def is_team_admin? team
    team.team_memberships.where(team_member_id: self.id, role: TeamMembership.roles[:admin]).any?
  end

  def has_pending_admin_requests? project
    self.admin_requests.where(project_id: project.id, status: AdminRequest.statuses[:pending]).any?
  end

end
