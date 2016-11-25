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
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :confirmable

  # mount_uploader :picture, PictureUploader
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

  has_many :chatrooms
  has_many :groupmembers
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

  def self.current_user
    Thread.current[:current_user]
  end

  def self.current_user=(usr)
    Thread.current[:current_user] = usr
  end

  def assign_address

    access_token = access_wallet
    Rails.logger.info access_token unless Rails.env == "development"
    api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
    secure_passphrase = self.password || self.encrypted_password
    secure_label = SecureRandom.hex(5)
    new_address = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)
    userKeychain = new_address["userKeychain"]
    backupKeychain = new_address["backupKeychain"]
    Rails.logger.info "Wallet Passphrase #{secure_passphrase}" unless Rails.env == "development"
    new_address_id = new_address["wallet"]["id"] rescue "assigning new address ID"
    puts "New Wallet Id #{new_address_id}" unless Rails.env == "development"
    new_wallet_address_sender = api.create_address(wallet_id: new_address_id, chain: "0", access_token: access_token) rescue "create address"
    new_wallet_address_receiver = api.create_address(wallet_id: new_address_id, chain: "1", access_token: access_token) rescue "address receiver"
    Rails.logger.info new_wallet_address_sender.inspect unless Rails.env == "development"
    Rails.logger.info new_wallet_address_receiver.inspect unless Rails.env == "development"
    Rails.logger.info "#Address #{new_wallet_address_sender["address"]}" rescue 'Address not Created'
    Rails.logger.info "#Address #{new_wallet_address_receiver["address"]}" rescue 'Address not Created'
    unless new_address.blank?
      UserWalletAddress.create(sender_address: new_wallet_address_sender["address"], receiver_address: new_wallet_address_receiver["address"], pass_phrase: secure_passphrase, user_id: self.id, wallet_id: new_address_id, user_keys: userKeychain, backup_keys: backupKeychain)
    else
      UserWalletAddress.create(sender_address: nil, user_id: self.id)
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

  def populate_guid_and_token
    random = SecureRandom.uuid()
    arbitraryAuthPayload = {:uid => random, :auth_data => random, :other_auth_data => self.created_at.to_s}
    generator = Firebase::FirebaseTokenGenerator.new("ZWx3jy7jaz8IuPXjJ8VNlOMlOMGFEIj0aHNE7tMt")
    random2 = generator.create_token(arbitraryAuthPayload)
    self.guid = random
    self.chat_token = random2
    self.save
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    if user
      user
    else
      registered_user = User.where(:email => auth.info.email).first
      if registered_user
        return registered_user
      else
        user = User.create(
            provider: auth.provider,
            uid: auth.uid,
            name: auth.info.name,
            email: auth.info.email,
            password: Devise.friendly_token[0, 20],
            picture: auth.info.image,
            facebook_url: auth.extra.link,
        )
      end
    end
  end

  def self.find_for_twitter_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    if user
      user
    else
      registered_user = User.where(:email => auth.uid + "@twitter.com").first
      if registered_user
        registered_user
      else

        user = User.create(
            provider: auth.provider,
            uid: auth.uid,
            name: auth.info.name,
            email: auth.uid+"@twitter.com",
            password: Devise.friendly_token[0, 20],
            picture: auth.info.image,
            description: auth.info.description,
            country: auth.info.location,
            twitter_url: auth.info.urls.Twitter,
        )
      end

    end
  end

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:provider => access_token.provider, :uid => access_token.uid).first
    if user
      user
    else
      registered_user = User.where(:email => access_token.info.email).first
      if registered_user
        registered_user
      else
        user = User.create(
            provider: access_token.provider,
            email: data["email"],
            uid: access_token.uid,
            name: access_token.info.name,
            password: Devise.friendly_token[0, 20],
            picture: access_token.info.image,
            company: access_token.extra.raw_info.hd,
        )
      end
    end
  end

  def is_admin_for? proj
    proj.user_id == self.id || proj_admins.where(project_id: proj.id).exists?
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

  # MediaWiki API - Page Read
  def page_read pagename
    if Rails.configuration.mediawiki_session
      name = pagename.strip.gsub(" ", "_")

      result = RestClient.get("http://wiki.weserve.io/api.php?action=weserve&method=read&page=#{name}&format=json", {:cookies => Rails.configuration.mediawiki_session})
      parsedResult = JSON.parse(result.body)

      if parsedResult["error"]
        content = Hash.new
        content["status"] = "error"
      else
        content = Hash.new
        content["non-html"] = parsedResult["response"]["content"]
        content["html"] = parsedResult["response"]["contentHtml"]
        content["status"] = "success"
      end

      content
    else
      0
    end
  end

  # MediaWiki API - Page Create or Write
  def page_write pagename, content
    if Rails.configuration.mediawiki_session
      name = pagename.strip.gsub(" ", "_")

      result = RestClient.post("http://wiki.weserve.io/api.php?action=weserve&method=write&format=json", {page: "#{name}", user: self.email, content: "#{content}"}, {:cookies => Rails.configuration.mediawiki_session})

      # Return Response Code
      JSON.parse(result.body)["response"]["code"]
    else
      0
    end
  end

  # MediaWiki API - Get latest revision
  def get_latest_revision pagename
    if Rails.configuration.mediawiki_session
      name = pagename.strip.gsub(" ", "_")

      # Get history
      history = RestClient.get("http://wiki.weserve.io/api.php?action=weserve&method=history&page=#{name}&format=json", {:cookies => Rails.configuration.mediawiki_session})
      latest_revision_id = JSON.parse(history.body)["response"][0]

      # Get the revision content
      revision = RestClient.get("http://wiki.weserve.io/api.php?action=weserve&method=revision&page=#{name}&revision=#{latest_revision_id}&format=json", {:cookies => Rails.configuration.mediawiki_session})

      JSON.parse(revision.body)["response"]["content"]
    else
      0
    end
  end

  def created_wallet_key
    if self.created_at > 3.minutes.ago
      true
    else
      false
    end
  end

end
