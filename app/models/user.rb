class User < ActiveRecord::Base
  enum role: [:user, :vip, :admin, :manager, :moderator]
  after_initialize :set_default_role, :if => :new_record?

  mount_uploader :picture, PictureUploader
  crop_uploaded :picture

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h

  def set_default_role
    self.role ||= :user
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :omniauthable, :confirmable

  #after_create :populate_guid_and_token

  has_many :projects, dependent: :destroy
  has_many :project_edits, dependent: :destroy
  has_many :project_comments, dependent: :delete_all
  has_many :activities, dependent: :delete_all
  has_many :do_requests, dependent: :delete_all
  has_many :do_for_frees
  has_many :assignments, dependent: :delete_all
  has_many :donations
  has_many :proj_admins, dependent: :delete_all

  has_many :groupmembers, dependent: :destroy
  has_many :chatrooms, through: :groupmembers, dependent: :destroy
  has_many :user_message_read_flags, dependent: :destroy
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
  has_many :apply_requests, dependent: :destroy
  has_many :stripe_payments
  has_one :wallet, as: :wallet_owner

  validate :validate_name_unchange
  validates :name, presence: true, uniqueness: true

  # Ref: https://github.com/plataformatec/devise/blob/88724e10adaf9ffd1d8dbfbaadda2b9d40de756a/lib/devise/models/validatable.rb
  # Validate everything as using `devise :validatable`
  # Except for validates_length_of password which is done only if no errors on password_confirmation were found
  validates_presence_of   :email, if: :email_required?
  validates_uniqueness_of :email, allow_blank: true, if: :email_changed?
  validates_format_of     :email, with: Devise.email_regexp, allow_blank: true, if: :email_changed?

  validates_presence_of     :password, if: :password_required?
  validates_confirmation_of :password, if: :password_required?

  # Override
  validates_length_of       :password, within: Devise.password_length, allow_blank: true, if: ->(user) { user.errors[:password_confirmation].blank? }

  scope :name_like, -> (name) { where('name ILIKE ?', "%#{name}%")}

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def self.current_user
    Thread.current[:current_user]
  end

  def self.current_user=(usr)
    Thread.current[:current_user] = usr
  end

  def current_wallet_balance
    wallet ? wallet.balance : 0.0
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

  def get_users_projects_and_team_projects
    (self.projects + self.teams.collect{ |t| t.project }).uniq
  end

  def all_dm_chatroom_users
    chatroom_ids = self.chatrooms.where(chatroom_type: 3).pluck(:id)
    Groupmember.where(chatroom_id: chatroom_ids).where.not(user_id: self.id).collect(&:user).uniq.sort_by(&:name)
  end

  def number_of_unread_messages
    self.user_message_read_flags.unread.count
  end

  def self.find_for_facebook_oauth(auth)
    user = User.find_by(provider: auth.provider, uid: auth.uid)
    return user if user.present?

    registered_user = User.find_by(email: auth.info.email)

    if registered_user
      registered_user.assign_attributes(
        provider: auth.provider,
        uid: auth.uid,
        name: auth.info.name,
        facebook_url: auth.extra.link,
        username: "#{auth.info.name}#{auth.uid}",
        remote_picture_url: auth.info.image.gsub('http://', 'https://')
      )

      registered_user.remote_picture_url = auth.info.image.gsub('http://', 'https://') unless registered_user.picture?

      registered_user.save
      registered_user
    else
      User.create(
        provider: auth.provider,
        uid: auth.uid,
        name: auth.info.name,
        email: auth.info.email,
        confirmed_at: DateTime.now,
        password: Devise.friendly_token[0, 20],
        facebook_url: auth.extra.link,
        username: auth.info.name + auth.uid,
        remote_picture_url: auth.info.image.gsub('http://', 'https://')
      )
    end
  end

  def self.find_for_twitter_oauth(auth)
    user = User.find_by(provider: auth.provider, uid: auth.uid)
    return user if user.present?

    registered_user = auth.info.email ? User.find_by(email: auth.info.email) : nil

    if registered_user
      registered_user.assign_attributes(
        provider: auth.provider,
        uid: auth.uid,
        name: auth.info.name,
        twitter_url: auth.info.urls.Twitter,
        username: "#{auth.info.name}#{auth.uid}",
        remote_picture_url: auth.info.image.gsub('http://', 'https://')
      )

      registered_user.remote_picture_url = auth.info.image.gsub('http://', 'https://') unless registered_user.picture?
      registered_user.description = auth.info.description unless registered_user.description?
      registered_user.country = auth.info.location unless registered_user.country?

      registered_user.save
      registered_user
    else
      User.create(
        provider: auth.provider,
        uid: auth.uid,
        name: auth.info.name,
        email: "#{auth.uid}@twitter.com",
        password: Devise.friendly_token[0, 20],
        confirmed_at: DateTime.now,
        description: auth.info.description,
        country: auth.info.location,
        twitter_url: auth.info.urls.Twitter,
        username: "#{auth.info.name}#{auth.uid}",
        remote_picture_url: auth.info.image.gsub('http://', 'https://')
      )
    end
  end

  def self.find_for_google_oauth2(access_token)
    user = User.find_by(provider: access_token.provider, uid: access_token.uid)
    return user if user.present?

    data = access_token.info
    registered_user = User.find_by(email: data['email'])

    if registered_user
      registered_user.assign_attributes(
        provider: access_token.provider,
        uid: access_token.uid,
        name: access_token.info.name,
        username: "#{access_token.info.name}#{access_token.uid}",
        company: access_token.extra.raw_info.hd,
        remote_picture_url: access_token.info.image.gsub('http://', 'https://')
      )

      registered_user.company = access_token.extra.raw_info.hd unless registered_user.company?
      registered_user.remote_picture_url = access_token.info.image.gsub('http://', 'https://') unless registered_user.picture?

      registered_user.save
      registered_user
    else
      User.create(
        provider: access_token.provider,
        email: data['email'],
        uid: access_token.uid,
        name: access_token.info.name,
        confirmed_at: DateTime.now,
        password: Devise.friendly_token[0, 20],
        company: access_token.extra.raw_info.hd,
        username: "#{access_token.info.name}#{access_token.uid}",
        remote_picture_url: access_token.info.image.gsub('http://', 'https://')
      )
    end
  end

  def is_admin_for? proj
    proj.user_id == self.id || proj_admins.where(project_id: proj.id).exists?
  end

  def is_coordinator_for?(project)
    team_membership = project.team_memberships.find_by(team_member_id: self.id)
    team_membership.present? && team_membership.coordinator?
  end

  def is_lead_editor_for? proj
    team_membership = proj.team_memberships.find_by(team_member_id: self.id)
    team_membership.present? && team_membership.lead_editor?
  end

  def is_teammate_for? proj
    if proj.team.team_memberships.where(:team_member_id => self.id).present?
      return (proj.team.team_memberships.where(:team_member_id => self.id).first.role == "teammate")
    else
      return false
    end
  end

  def is_team_member_for?(project)
    project.user_id == self.id || proj_admins.where(project_id: project.id).exists? || project.team.team_memberships.where(:team_member_id => self.id).present?
  end

  def is_project_leader?(project)
    project.user.id == self.id
  end

  def is_teammember_for?(task)
    task_memberships = task.project.team.team_memberships
    task_memberships.collect(&:team_member_id).include? self.id
  end

  def can_apply_as_admin?(project)
    !self.is_project_leader?(project) && !self.is_team_admin?(project.team) && !self.has_pending_admin_requests?(project)
  end

  def is_team_admin?(team)
    team.team_memberships.where(team_member_id: self.id, role: TeamMembership.roles[:admin]).any?
  end

  def has_pending_admin_requests?(project)
    self.admin_requests.where(project_id: project.id, status: AdminRequest.statuses[:pending]).any?
  end

  def has_pending_apply_requests?(proj, type)
    self.apply_requests.where(project_id: proj.id, request_type: type).pending.any?
  end

  def can_submit_task?(task)
    task_memberships = task.team_memberships
    task.doing? && (task_memberships.collect(&:team_member_id).include? self.id) && self.is_teammate_for?(task.project)
  end

  def can_complete_task?(task)
    (self.is_project_leader?(task.project) || self.is_coordinator_for?(task.project)) && task.reviewing?
  end

  # Normal use case, name cannot be changed, need to bypass validation if neccessary
  def validate_name_unchange
    errors.add(:name, 'is not allowed to change') if name_changed? && self.persisted?
  end

  protected

  # Checks whether a password is needed or not. For validations only.
  # Passwords are always required if it's a new record, or if the password
  # or confirmation are being set somewhere.
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def email_required?
    true
  end
end
