class User < ActiveRecord::Base
  include ApplicationHelper
  enum role: [:user, :vip, :admin, :manager, :moderator]
  after_initialize :set_default_role, :if => :new_record?

  mount_uploader :picture, PictureUploader
  crop_uploaded :picture

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h

  searchable do
    text :name
  end

  def set_default_role
    self.role ||= :user
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :confirmable

  #after_create :populate_guid_and_token

  after_create :assign_address

  has_many :projects, dependent: :destroy
  has_many :project_edits, dependent: :destroy
  has_many :project_comments, dependent: :delete_all
  has_many :activities, dependent: :delete_all
  has_many :do_requests, dependent: :delete_all
  has_many :do_for_frees
  has_many :assignments, dependent: :delete_all
  has_many :donations
  has_many :proj_admins, dependent: :delete_all

  has_many :chatrooms, dependent: :destroy
  has_many :groupmembers, dependent: :destroy
  # users can send each other profile comments
  has_many :profile_comments, foreign_key: "receiver_id", dependent: :destroy
  has_many :project_rates
  has_many :team_memberships, foreign_key: "team_member_id"
  has_many :teams, :through => :team_memberships
  has_many :conversations, foreign_key: "sender_id"
  has_many :project_users
  has_many :followed_projects, through: :project_users, class_name: 'Project', source: :project
  has_many :discussions, dependent: :destroy
  has_one :user_wallet_address
  has_many :notifications, dependent: :destroy
  has_many :admin_requests, dependent: :destroy
  has_many :apply_requests, dependent: :destroy

  validates :name, presence: true,uniqueness: true

  def self.current_user
    Thread.current[:current_user]
  end

  def self.current_user=(usr)
    Thread.current[:current_user] = usr
  end

  def assign_address
    if File.basename($0) != 'rake'

      access_token = access_wallet
      Rails.logger.info access_token unless Rails.env == "development"
      api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
      secure_passphrase =  self.encrypted_password
      secure_label = SecureRandom.hex(5)
      new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)
      userKeychain = new_address["userKeychain"]
      backupKeychain = new_address["backupKeychain"]
      new_address_id = new_address["wallet"]["id"] rescue "assigning new address ID"
      new_wallet_address_sender = api.create_address(wallet_id: new_address_id, chain: "0", access_token: access_token) rescue "create address"
      new_wallet_address_receiver = api.create_address(wallet_id: new_address_id, chain: "1", access_token: access_token) rescue "address receiver"
      unless new_address.blank?
        UserWalletAddress.create(sender_address: new_wallet_address_sender["address"], receiver_address: new_wallet_address_receiver["address"], pass_phrase: secure_passphrase, user_id: self.id, wallet_id: new_address_id, user_keys: userKeychain, backup_keys: backupKeychain)
      else
        UserWalletAddress.create(sender_address: nil, user_id: self.id)
      end

    end
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

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    if user
      user.update(
        remote_picture_url: auth.info.image.gsub('http://', 'https://')
      )
      user
    else
      registered_user = User.where(:email => auth.info.email).first
      if registered_user
        registered_user.update(
          provider: auth.provider,
          uid: auth.uid,
          name: auth.info.name,
          facebook_url: auth.extra.link,
          username: auth.info.name + auth.uid,
          remote_picture_url: auth.info.image.gsub('http://', 'https://')
        )
        registered_user
      else
        user = User.create(
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
  end

  def self.find_for_twitter_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    if user
      user.update(
        description: auth.info.description,
        country: auth.info.location,
        remote_picture_url: auth.info.image.gsub('http://', 'https://')
      )
      user
    else
      registered_user = User.where(:email => auth.uid + "@twitter.com").first
      if registered_user
        registered_user.update(
          provider: auth.provider,
          uid: auth.uid,
          name: auth.info.name,
          twitter_url: auth.info.urls.Twitter,
          username: auth.info.name + auth.uid,
          description: auth.info.description,
          country: auth.info.location,
          remote_picture_url: auth.info.image.gsub('http://', 'https://')
        )
        registered_user
      else

        user = User.create(
          provider: auth.provider,
          uid: auth.uid,
          name: auth.info.name,
          email: auth.uid+"@twitter.com",
          password: Devise.friendly_token[0, 20],
          confirmed_at: DateTime.now,
          description: auth.info.description,
          country: auth.info.location,
          twitter_url: auth.info.urls.Twitter,
          username: auth.info.name + auth.uid,
          remote_picture_url: auth.info.image.gsub('http://', 'https://')
        )
      end

    end
  end

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:provider => access_token.provider, :uid => access_token.uid).first
    if user
      user.update(
        company: access_token.extra.raw_info.hd,
        remote_picture_url: access_token.info.image.gsub('http://', 'https://')
      )
      user
    else
      registered_user = User.where(:email => data["email"]).first
      if registered_user
        registered_user.update(
          provider: access_token.provider,
          uid: access_token.uid,
          name: access_token.info.name,
          username: access_token.info.name + access_token.uid,
          company: access_token.extra.raw_info.hd,
          remote_picture_url: access_token.info.image.gsub('http://', 'https://')
        )
        registered_user
      else
        user = User.create(
            provider: access_token.provider,
            email: data["email"],
            uid: access_token.uid,
            name: access_token.info.name,
            confirmed_at: DateTime.now,
            password: Devise.friendly_token[0, 20],   
            company: access_token.extra.raw_info.hd,
            username: access_token.info.name + access_token.uid,
            remote_picture_url: access_token.info.image.gsub('http://', 'https://')
        )
      end
    end
  end

  def is_admin_for? proj
    proj.user_id == self.id || proj_admins.where(project_id: proj.id).exists?
  end

  #Comment out this codes since we cannot get appropriate result from this

  # def is_executor_for? proj
  #   proj.executors.pluck(:id).include? self.id
  # end

  # def is_lead_editor_for? proj
  #   proj.lead_editors.pluck(:id).include? self.id
  # end

  def is_executor_for? proj
    if proj.team.team_memberships.where(:team_member_id => self.id).present?
      return (proj.team.team_memberships.where(:team_member_id => self.id).first.role == "executor")
    else
      return false
    end
  end

  def is_lead_editor_for? proj
    if proj.team.team_memberships.where(:team_member_id => self.id).present?
      return (proj.team.team_memberships.where(:team_member_id => self.id).first.role == "lead_editor")
    else
      return false
    end
  end

  def can_apply_as_admin?(project)
    !self.is_project_leader?(project) && !self.is_team_admin?(project.team) && !self.has_pending_admin_requests?(project)
  end

  def is_project_leader?(project)
    project.user.id == self.id
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


end
