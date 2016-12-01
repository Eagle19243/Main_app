class Project < ActiveRecord::Base

  acts_as_paranoid

  include Discussable
  paginates_per 9
  include AASM
  default_scope -> { order('projects.created_at DESC') }
  mount_uploader :picture, PictureUploader
  crop_uploaded :picture

  attr_accessor :discussed_description, :crop_x, :crop_y, :crop_w, :crop_h

  has_many :tasks, dependent: :delete_all
  has_many :wikis, dependent: :delete_all
  has_many :project_comments, dependent: :delete_all
  has_many :project_edits, dependent: :destroy
  has_many :proj_admins
  has_one :chat_room
  has_one :chatroom, dependent: :destroy
  has_many :project_rates
  has_many :project_users
  has_many :section_details, dependent: :destroy
  has_many :followers, through: :project_users, class_name: 'User', source: :follower, dependent: :destroy
  has_one :team, dependent: :destroy
  has_many :change_leader_invitations

  belongs_to :user

  validates :title, presence: true, length: {minimum: 3, maximum: 60},
            uniqueness: true
  validates :short_description, presence: true, length: {minimum: 3, maximum: 60, message: "Has invalid length"}
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
    needed_budget == 0 ? "100%" : (funded_budget/needed_budget*100).round.to_s + "%"
  end

  def accepted_tasks
    tasks.where(state: 'accepted')
  end

  def tasks_relations_string
    accepted_tasks.count.to_s + " / " + tasks.count.to_s
  end

  def team_relations_string
    # self.team.team_memberships.count.to_s
    # tasks.sum(:number_of_participants).to_s + " / " + tasks.sum(:target_number_of_participants).to_s
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

  # MediaWiki API - Page Read
  def page_read
    if Rails.configuration.mediawiki_session
      name = self.title.strip.gsub(" ", "_")

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
  def page_write user, content
    if Rails.configuration.mediawiki_session
      name = self.title.strip.gsub(" ", "_")

      result = RestClient.post("http://wiki.weserve.io/api.php?action=weserve&method=write&format=json", {page: "#{name}", user: user.email, content: "#{content}"}, {:cookies => Rails.configuration.mediawiki_session})

      # Return Response Code
      JSON.parse(result.body)["response"]["code"]
    else
      0
    end
  end

  # MediaWiki API - Get latest revision
  def get_latest_revision
    if Rails.configuration.mediawiki_session
      name = self.title.strip.gsub(" ", "_")

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

  # MediaWiki API - Get history
  def get_history
    if Rails.configuration.mediawiki_session
      name = self.title.strip.gsub(" ", "_")

      # Get history
      history = RestClient.get("http://wiki.weserve.io/api.php?action=weserve&method=history&page=#{name}&format=json", {:cookies => Rails.configuration.mediawiki_session})
      JSON.parse(history.body)["response"]
    else
      0
    end
  end

  # MediaWiki API - Get revision
  def get_revision revision_id
    if Rails.configuration.mediawiki_session
      name = self.title.strip.gsub(" ", "_")

      # Get revision
      revision = RestClient.get("http://wiki.weserve.io/api.php?action=weserve&method=revision&page=#{name}&revision=#{revision_id}&format=json", {:cookies => Rails.configuration.mediawiki_session})
      JSON.parse(revision.body)["response"]
    else
      0
    end
  end

  # MediaWiki API - Approve Revision by id
  def approve_revision revision_id
    if Rails.configuration.mediawiki_session
      name = self.title.strip.gsub(" ", "_")

      # Approve
      result = RestClient.get("http://wiki.weserve.io/api.php?action=weserve&method=approve&page=#{name}&revision=#{revision_id}&format=json", {:cookies => Rails.configuration.mediawiki_session})
      JSON.parse(result.body)["response"]["code"]
    else
      0
    end
  end

  # MediaWiki API - Unapprove Revision by id
  def unapprove_revision revision_id
    if Rails.configuration.mediawiki_session
      name = self.title.strip.gsub(" ", "_")

      # Unapprove
      result = RestClient.get("http://wiki.weserve.io/api.php?action=weserve&method=unapprove&page=#{name}&revision=#{revision_id}&format=json", {:cookies => Rails.configuration.mediawiki_session})
      JSON.parse(result.body)["response"]["code"]
    else
      0
    end
  end
end
