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
  has_many :chatrooms, dependent: :destroy
  has_many :project_rates
  has_many :project_users
  has_many :section_details, dependent: :destroy
  has_many :followers, through: :project_users, class_name: 'User', source: :follower, dependent: :destroy
  has_many :coordinators, through: :project_users, class_name: 'User', source: :coordinator, dependent: :destroy
  has_many :lead_editors, through: :project_users, class_name: 'User', source: :lead_editor, dependent: :destroy
  has_one  :team, dependent: :destroy
  has_many :team_memberships, through: :team
  has_many :team_members, through: :team
  has_many :change_leader_invitations
  has_many :apply_requests, dependent: :destroy

  belongs_to :user

  # Define better that the association user is referring to the leader of the project
  alias_method :leader, :user

  SHORT_DESCRIPTION_LIMIT = 250

  validates :title, presence: true, length: {minimum: 3, maximum: 60},
            uniqueness: {case_sensitive: false}
  validates :wiki_page_name, presence: true, uniqueness: true
  validates :short_description, presence: true, length: {minimum: 3, maximum: SHORT_DESCRIPTION_LIMIT, message: "Has invalid length. Min length is 3, max length is #{SHORT_DESCRIPTION_LIMIT}"}
  accepts_nested_attributes_for :section_details, allow_destroy: true, reject_if: ->(attributes) { attributes['project_id'].blank? && attributes['parent_id'].blank? }

  accepts_nested_attributes_for :project_edits, :reject_if => :all_blank, :allow_destroy => true

  after_restore :unarchive

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

  scope :not_hidden, -> { where(hidden: false) }

  # TODO In future it would be a good idea to extract this into the Search object
  def self.fulltext_search(free_text, limit=20)
    # TODO Rails 5 has a OR method
    projects = Project.where("title ILIKE ? OR description ILIKE ? OR short_description ILIKE ? OR full_description ILIKE ?", "%#{free_text}%", "%#{free_text}%", "%#{free_text}%","%#{free_text}%")
    projects.limit(limit)
  end

  def interested_users
    (team_members + followers + [leader]).uniq
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
    Payments::BTC::Converter.convert_satoshi_to_btc(tasks.sum(:satoshi_budget))
  end

  def funded_budget
    Payments::BTC::Converter.convert_satoshi_to_btc(tasks.map(&:wallet).compact.map(&:balance).inject(0, &:+))
  end

  def funded_percentages
    needed_budget == 0 ? "-" : (funded_budget/needed_budget*100).round.to_s + "%"
  end

  def accepted_tasks
    tasks.where(state: 'accepted')
  end

  def completed_tasks
    tasks.where(state: 'completed')
  end

  def tasks_relations_string
    "#{completed_tasks.count} / #{tasks.count}"
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

  def team_memberships_count
    if self.team.present?
      self.team.team_memberships.count
    else
      0
    end
  end

  def all_team_memberships_except(user)
    self.team_memberships.joins(:team_member).where.not(team_member: user).order('users.username ASC')
  end

  def get_project_chatroom
    self.chatrooms.where(chatroom_type: 1).first
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

  def pending_change_leader?(user)
    project.change_leader_invitations.pending.where(user.email).count > 0
  end

  def follow!(user)
    self.project_users.create(user_id: user.id)
    NotificationsService.notify_about_follow_project(self, user)
  end

  def unfollow!(user)
    self.project_users.where(user_id: user.id).destroy_all
  end

  def is_approval_enabled?
    self.is_approval_enabled
  end

  def hide!
    self.hidden = true
    self.save
  end

  def un_hide!
    self.hidden = false
    self.save
  end

  # Load MediaWiki API Base URL from application.yml
  def self.load_mediawiki_api_base_url
    ENV['mediawiki_api_base_url']
  end

  # MediaWiki API - Page Read
  def page_read(username = nil)
    parsedResult = username.blank? ? get(:read) : get(:read, user: username)
    return nil if parsedResult.blank?
    {}.tap do |content|
      if parsedResult["error"]
        content["status"] = "error"
      else
        content["revision_id"] = parsedResult["response"]["revision_id"]
        content["non-html"] = parsedResult["response"]["content"]
        content["html"] = parsedResult["response"]["contentHtml"]
        content["is_blocked"] = parsedResult["response"]["is_blocked"]
        content["status"] = "success"
      end
    end
  end

  # MediaWiki API - Page Create or Write
  def page_write(user, content)
    post(:write, { content: content }, user: user.username)
      .try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - Get latest revision
  def get_latest_revision
    revision = get_revision(get_history.try(:[], 0).try(:[], 'id'))
    revision.try(:[], 'content')
  end

  # MediaWiki API - Get history
  def get_history
    get(:history).try(:[], 'response')
  end

  # MediaWiki API - Get revision
  def get_revision(revision_id)
    get(:revision, revision: revision_id).try(:[], 'response')
  end

  # MediaWiki API - Approve Revision by id
  def approve_revision(revision_id)
    get(:approve, revision: revision_id).try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - Unapprove Revision by id
  def unapprove_revision(revision_id)
    get(:unapprove, revision: revision_id).try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - Unapprove approved revision
  def unapprove
    get(:unapprove).try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - Block user
  def block_user(username)
    get(:block, user: username).try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - Unblock user
  def unblock_user(username)
    get(:unblock, user: username).try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - Change page title
  def rename_page(username, old_title)
    new_title = set_project_name(wiki_page_name, title)
    old_title = old_title.tr(' ', '_')
    get(:move, user: username, page: old_title, page_new: new_title)
      .try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - Grant permissions to user
  def grant_permissions(username)
    get(:grant, user: username).try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - Revoke permissions from user
  def revoke_permissions(username)
    get(:revoke, user: username).try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - archive (safe delete) a page
  def archive(username)
    get(:delete, user: username).try(:[], 'response').try(:[], 'code')
  end

  # MediaWiki API - un-archive (restore) a page
  def unarchive(username = User.current_user)
    get(:restore, user: username).try(:[], 'response').try(:[], 'code')
  end

  private

  def set_project_name(wiki_page_name, title)
    if wiki_page_name.present? then wiki_page_name.tr(" ", "_") else title.strip.tr(" ", "_") end
  end

  def get(action, params = {})
    base_request(action, params) do |url, opts|
      RestClient.get(url, opts)
    end
  end

  def post(action, params = {}, data = {})
    base_request(action, params) do |url, opts|
      RestClient.post(url, data, opts)
    end
  end

  def base_request(action, params = {})
    return nil unless Rails.configuration.mediawiki_session
    params[:action] ||= :weserve
    params[:method] ||= action
    params[:format] ||= :json
    params[:page] ||= set_project_name(wiki_page_name, title)

    base_url = "#{Project.load_mediawiki_api_base_url}api.php?#{to_url(params)}"
    puts "request to wiki: #{base_url}"
    result = yield base_url, cookies: Rails.configuration.mediawiki_session
    puts "Received response from wiki #{result}"
    JSON.parse(result.body)
  # rescue => error
  #   Rails.logger.debug "Failed to call Mediawiki api #{error}"
  #   nil
  end

  def to_url(params)
    URI.escape(params.collect { |k, v| "#{k}=#{v}" }.join('&')) if params
  end
end
