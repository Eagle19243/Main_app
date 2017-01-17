class Project < ActiveRecord::Base

  acts_as_paranoid

  include Discussable
  paginates_per 9
  include AASM
  default_scope -> { order('projects.created_at DESC') }
  mount_uploader :picture, PictureUploader
  crop_uploaded :picture

  attr_accessor :discussed_description, :crop_x, :crop_y, :crop_w, :crop_h

  has_many :tasks, dependent: :destroy
  has_many :wikis, dependent: :destroy
  has_many :project_comments, dependent: :destroy
  has_many :project_edits, dependent: :destroy
  has_many :proj_admins, dependent: :destroy
  has_one :chat_room
  has_one :chatroom, dependent: :destroy
  has_many :project_rates
  has_many :project_users
  has_many :section_details, dependent: :destroy
  has_many :followers, through: :project_users, class_name: 'User', source: :follower, dependent: :destroy
  has_many :executors, through: :project_users, class_name: 'User', source: :executor, dependent: :destroy
  has_many :lead_editors, through: :project_users, class_name: 'User', source: :lead_editor, dependent: :destroy
  has_one :team, dependent: :destroy
  has_many :change_leader_invitations
  has_many :apply_requests, dependent: :destroy

  belongs_to :user

  validates :title, presence: true, length: {minimum: 3, maximum: 60},
            uniqueness: true
  validates :wiki_page_name, presence: true, uniqueness: true
  validates :short_description, presence: true, length: {minimum: 3, maximum: 60, message: "Has invalid length. Max length is 60"}
  accepts_nested_attributes_for :section_details, allow_destroy: true, reject_if: ->(attributes) { attributes['project_id'].blank? && attributes['parent_id'].blank? }

  searchable do
    text :title
    text :description
    text :short_description
  end
  validates :picture, presence: true
  accepts_nested_attributes_for :project_edits, :reject_if => :all_blank, :allow_destroy => true

  aasm column: 'state', whiny_transitions: false do
    state :pending
    state :accepted
    state :rejected

    event :accept do
      transitions :from => :pending, :to => :accepted
    end

    event :reject do
      transitions :from => :pending, :to => :rejected
    end
  end

  def video_url
    video_id ||= "H30roqZiHRQ"
    "https://www.youtube.com/embed/#{video_id}"
  end

  def self.get_featured_projects
    Project.last(6)
  end

  def country_name
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end

  def needed_budget
    tasks.sum(:budget)
  end

  def funded_budget
    tasks.sum(:current_fund)
  end

  def funded_percentages
    needed_budget == 0 ? "100%" : (funded_budget/needed_budget*100).round.to_s + " %"
  end

  def accepted_tasks
    tasks.where(state: 'accepted')
  end

  def tasks_relations_string
    accepted_tasks.count.to_s + " / " + tasks.count.to_s
  end

  def team_relations_string
    if team.nil?
      return tasks.sum(:number_of_participants).to_s + " / " + tasks.sum(:target_number_of_participants).to_s
    else
      return team.team_memberships.count.to_s + " / " + tasks.sum(:target_number_of_participants).to_s
    end
    # self.team.team_memberships.count.to_s
    #tasks.sum(:number_of_participants).to_s + " / " + tasks.sum(:target_number_of_participants).to_s
  end

  def rate_avg
    project_rates.average(:rate).to_i
  end

  def can_update?
    User.current_user.is_admin_for?(self)
  end

  def section_details_list parent = nil
    result = []
    section_details.of_parent(parent).ordered.each do |child|
      result << child
      result += section_details_list(child) if child.childs.exists?
    end
    result
  end

  def discussed_description= value
    if can_update?
      self.send(:write_attribute, 'description', value)
    else
      unless value == self.description.to_s
        Discussion.find_or_initialize_by(discussable: self, user_id: User.current_user.id, field_name: 'description').update_attributes(context: value)
      end
    end
  end

  def discussed_description
    can_update? ?
        self.send(:read_attribute, 'description') :
        discussions.of_field('description').of_user(User.current_user).last.try(:description) || self.send(:read_attribute, 'description')
  end

  def self.get_project_default_chat_room(project_id, user_id)
    Chatroom.select(:id).where("project_id = ? AND user_id = ?", project_id, user_id).first.id rescue nil
  end

  def pending_change_leader?(user)
    project.change_leader_invitations.pending.where(user.email).count > 0
  end

  def follow!(user)
    self.project_users.create(user_id: user.id)
  end

  def unfollow!(user)
    self.project_users.where(user_id: user.id).destroy_all
  end

  def is_approval_enabled?
    self.is_approval_enabled
  end

  # Load MediaWiki API Base URL from application.yml
  def self.load_mediawiki_api_base_url
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    settings['mediawiki']['api_base_url']
  end

  # MediaWiki API - Page Read
  def page_read username
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      begin
        if username == nil
          result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=read&page=#{URI.escape(name)}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        else
          result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=read&page=#{URI.escape(name)}&user=#{URI.escape(username)}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        end
        parsedResult = JSON.parse(result.body)

        if parsedResult["error"]
          content = Hash.new
          content["status"] = "error"
        else
          content = Hash.new
          content["revision_id"] = parsedResult["response"]["revision_id"]
          content["non-html"] = parsedResult["response"]["content"]
          content["html"] = parsedResult["response"]["contentHtml"]
          content["is_blocked"] = parsedResult["response"]["is_blocked"]
          content["status"] = "success"
        end
      rescue
        return nil
      end

      content
    else
      nil
    end
  end

  # MediaWiki API - Page Create or Write
  def page_write user, content
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      begin
        result = RestClient.post("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=write&page=#{URI.escape(name)}&content=#{content}&format=json", {user: user.username}, {:cookies => Rails.configuration.mediawiki_session})
      rescue
        return nil
      end
      # Return Response Code
      JSON.parse(result.body)["response"]["code"]
    else
      nil
    end
  end

  # MediaWiki API - Get latest revision
  def get_latest_revision
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      begin
        # Get history
        history = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=history&page=#{URI.escape(name)}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        latest_revision_id = JSON.parse(history.body)["response"][0]

        # Get the revision content
        revision = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=revision&page=#{URI.escape(name)}&revision=#{latest_revision_id}&format=json", {:cookies => Rails.configuration.mediawiki_session})

        return JSON.parse(revision.body)["response"]["content"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Get history
  def get_history
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Get history
      begin
        history = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=history&page=#{URI.escape(name)}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        return JSON.parse(history.body)["response"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Get revision
  def get_revision revision_id
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Get revision
      begin
        revision = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=revision&page=#{URI.escape(name)}&revision=#{revision_id}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        return JSON.parse(revision.body)["response"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Approve Revision by id
  def approve_revision revision_id
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Approve
      begin
        result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=approve&page=#{URI.escape(name)}&revision=#{revision_id}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        return JSON.parse(result.body)["response"]["code"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Unapprove Revision by id
  def unapprove_revision revision_id
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Unapprove
      begin
        result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=unapprove&page=#{URI.escape(name)}&revision=#{revision_id}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        JSON.parse(result.body)["response"]["code"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Unapprove approved revision
  def unapprove
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Unapprove
      begin
        result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=unapprove&page=#{URI.escape(name)}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        JSON.parse(result.body)["response"]["code"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Block user
  def block_user username
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Block
      begin
        result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=block&page=#{URI.escape(name)}&user=#{username}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        JSON.parse(result.body)["response"]["code"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Unblock user
  def unblock_user username
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Unblock
      begin
        result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=unblock&page=#{URI.escape(name)}&user=#{username}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        JSON.parse(result.body)["response"]["code"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Change page title
  def rename_page username, old_title
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        new_title = self.wiki_page_name.gsub(" ", "_")
      else
        new_title = self.title.strip.gsub(" ", "_")
      end

      old_title = old_title.gsub(" ", "_")

      # Change page title
      begin
        result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=move&page=#{URI.escape(old_title)}&page_new=#{URI.escape(new_title)}&user=#{username}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        JSON.parse(result.body)["response"]["code"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Grant permissions to user
  def grant_permissions username
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Grant permissions to user
      begin
        result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=grant&page=#{URI.escape(name)}&user=#{username}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        JSON.parse(result.body)["response"]["code"]
      rescue
        return nil
      end
    else
      nil
    end
  end

  # MediaWiki API - Revoke permissions from user
  def revoke_permissions username
    if Rails.configuration.mediawiki_session
      if self.wiki_page_name.present?
        name = self.wiki_page_name.gsub(" ", "_")
      else
        name = self.title.strip.gsub(" ", "_")
      end

      # Revoke permissions from user
      begin
        result = RestClient.get("#{Project.load_mediawiki_api_base_url}api.php?action=weserve&method=revoke&page=#{URI.escape(name)}&user=#{username}&format=json", {:cookies => Rails.configuration.mediawiki_session})
        JSON.parse(result.body)["response"]["code"]
      rescue
        return nil
      end
    else
      nil
    end
  end

end
