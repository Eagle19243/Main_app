class User < ActiveRecord::Base
  enum role: [:user, :vip, :admin, :manager, :moderator]
  after_initialize :set_default_role, :if => :new_record?

  mount_uploader :picture, PictureUploader
  crop_uploaded :picture

  mount_uploader :background_picture, PictureUploader
  crop_uploaded :background_picture

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

  validate :validate_username_unchange
  validates :username, presence: true, uniqueness: true
  validates :phone_number, length: { minimum: 5, maximum: 15 }, allow_blank: true
  validates_format_of :phone_number, with: /\A\+?[0-9]*\z/

  # Ref: https://github.com/plataformatec/devise/blob/88724e10adaf9ffd1d8dbfbaadda2b9d40de756a/lib/devise/models/validatable.rb
  # Validate everything as using `devise :validatable`
  # Except for validates_length_of password which is done only if no errors on password_confirmation were found
  validates_presence_of   :email, if: :email_required?
  validates_uniqueness_of :email, allow_blank: true, if: :email_changed?
  validates_format_of     :email, with: Devise.email_regexp, allow_blank: true, if: :email_changed?

  validates_presence_of     :password, if: :password_required?
  validates_confirmation_of :password,  message: "doesn't match", if: :password_required?

  # Override
  validates_length_of       :password, within: Devise.password_length, allow_blank: true, if: ->(user) { user.errors[:password_confirmation].blank? }

  scope :name_like, -> (display_name) { where("username ILIKE ? OR CONCAT(first_name, ' ', last_name) ILIKE ?", "%#{display_name}%", "%#{display_name}%")}
  scope :not_hidden, -> { where(hidden: false) }

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
    Groupmember.where(chatroom_id: chatroom_ids).where.not(user_id: self.id).collect(&:user).uniq.sort_by(&:username)
  end

  def dm_chatroom_id_shared_with(user)
    (self.chatrooms.dm_chatrooms.pluck(:id) & user.chatrooms.where(chatroom_type: 3).pluck(:id)).first
  end

  def number_of_unread_messages
    self.user_message_read_flags.unread.count
  end

  def self.find_for_facebook_oauth(auth)
    registered_user = User.find_by(provider: auth.provider, uid: auth.uid)
    registered_user ||= User.find_by(email: auth.info.email)
    # return user if user.present?

    if registered_user
      registered_user.assign_attributes(
        provider: auth.provider,
        uid: auth.uid,
        first_name: auth.info.name.split(' ')[0],
        last_name: auth.info.name.split(' ')[1],
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
        first_name: auth.info.name.split(' ')[0],
        last_name: auth.info.name.split(' ')[1],
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
    registered_user = User.find_by(provider: auth.provider, uid: auth.uid)
    registered_user ||= auth.info.email ? User.find_by(email: auth.info.email) : nil

    if registered_user
      registered_user.assign_attributes(
        provider: auth.provider,
        uid: auth.uid,
        first_name: auth.info.name.split(' ')[0],
        last_name: auth.info.name.split(' ')[1],
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
        first_name: auth.info.name.split(' ')[0],
        last_name: auth.info.name.split(' ')[1],
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
    registered_user = User.find_by(provider: access_token.provider, uid: access_token.uid)
    data = access_token.info
    registered_user ||= User.find_by(email: data['email'])

    if registered_user
      registered_user.assign_attributes(
        provider: access_token.provider,
        uid: access_token.uid,
        first_name: access_token.info.name.split(' ')[0],
        last_name: access_token.info.name.split(' ')[1],
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
        first_name: access_token.info.name.split(' ')[0],
        last_name: access_token.info.name.split(' ')[1],
        confirmed_at: DateTime.now,
        password: Devise.friendly_token[0, 20],
        company: access_token.extra.raw_info.hd,
        username: "#{access_token.info.name}#{access_token.uid}",
        remote_picture_url: access_token.info.image.gsub('http://', 'https://')
      )
    end
  end

  # Method reports whether current user is an admin of the given project
  #
  # User is considered as an admin in project in any of these two cases:
  #
  #   * user is a creator of the project
  #   * user is invited admin of the project
  #
  # Returns boolean value
  def is_admin_for?(project)
    project.user_id == id || proj_admins.accepted.exists?(project_id: project.id)
  end

  # Method reports whether current user is a project leader in the given project
  #
  # Returns boolean value
  def is_project_leader?(project)
    project.user.id == self.id
  end

  # Method reports whether current user is a coordinator in the given project
  #
  # Returns boolean value
  def is_coordinator_for?(project)
    project.team_memberships.exists?(
      team_member_id: id,
      role: TeamMembership::COORDINATOR_ID
    )
  end

  # Method reports whether current user is either:
  #
  #  * project leader
  #  * coordinator
  #
  # (any of the following) in the given project
  #
  # Returns boolean value
  def is_project_leader_or_coordinator?(project)
    is_project_leader?(project) || is_coordinator_for?(project)
  end

  # Method reports whether current user is a lead editor in the given project
  #
  # Returns boolean value
  def is_lead_editor_for?(project)
    project.team_memberships.exists?(
      team_member_id: id,
      role: TeamMembership::LEAD_EDITOR_ID
    )
  end

  # Method reports whether current user is a teammate in the given project
  #
  # Returns boolean value
  def is_teammate_for?(project)
    project.team_memberships.exists?(
      team_member_id: id,
      role: TeamMembership::TEAM_MATE_ID
    )
  end

  # Method reports whether current user is involved in the given project by
  # either of these ways:
  #
  #   * user is an admin in this project
  #   * user is a teammate
  #   * user is a lead_editor
  #   * user is a leader
  #   * user is a coordinator
  #
  # Returns boolean value
  def is_project_team_member?(project)
    is_admin_for?(project) ||
      project.team_memberships.exists?(team_member_id: id)
  end

  def is_task_team_member?(task)
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

  # Normal use case, username cannot be changed, need to bypass validation if neccessary
  def validate_username_unchange
    errors.add(:username, 'is not allowed to change') if username_changed? && self.persisted?
  end

  # if real name(First name + Last name) is not empty, display it instead of username, otherwise keep username
  def display_name
    (first_name.blank? || last_name.blank?) ?  username : full_name
  end

  def full_name
    [first_name, last_name].join(" ")
  end

  # Autocomplete display result (used in GroupMessagesController)
  def search_display_results
    User.find(id).display_name
  end

  # Hide user and all projects he is a member of
  def hide!
    Project.all.each do |project|
      project.hide! if project.team_members.include? self
    end
    self.hidden = true
    self.save
  end

  # Un-hide (make visible) user and all projects he is a member of if owners of those projects aren't hidden
  def un_hide!
    self.hidden = false
    self.save
    Project.all.each do |project|
      project.un_hide! if ((project.team_members.include? self) && !project.user.hidden)
    end
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
