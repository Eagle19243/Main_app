class Project < ActiveRecord::Base
  include AASM

  default_scope -> { order('projects.created_at DESC') }

  mount_uploader :picture, PictureUploader
  mount_uploader :institution_logo, PictureUploader

  has_many :tasks, dependent: :delete_all
  has_many :wikis, dependent: :delete_all
  has_many :project_comments, dependent: :delete_all
  has_many :project_edits, dependent: :destroy
  has_many :proj_admins
  has_many :project_rates
  has_and_belongs_to_many :followed_users, join_table: :project_users, class_name: 'User'
  has_one :team

  belongs_to :user
  belongs_to :institution

  validates :title, presence: true, length: { minimum: 1, maximum: 60 },
                      uniqueness: true

  # validates :short_description, presence: true, length: { minimum: 100, maximum: 500 }
  #
  # validates :description, presence: true, length: { minimum: 2}
  #
  # validates :institution_description, presence: true, length: { minimum: 2}
  #
  # validates :institution_location, presence: true, length: {minimum: 2}
  #
  # validates :institution_country, presence: true,  length: {minimum: 2}
  # validates :picture, presence: true

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

  def location
    "#{institution_location} - #{institution_country}"
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
    tasks.sum(:number_of_participants).to_s + " / " + tasks.sum(:target_number_of_participants).to_s
  end
end
