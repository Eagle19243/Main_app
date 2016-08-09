class Project < ActiveRecord::Base
  include AASM

  default_scope -> { order('created_at DESC') }

  mount_uploader :picture, PictureUploader
  mount_uploader :institution_logo, PictureUploader

  has_many :tasks, dependent: :delete_all
  has_many :wikis, dependent: :delete_all
  has_many :project_comments, dependent: :delete_all
  has_many :project_edits, dependent: :destroy
  has_many :proj_admins
  has_one :chat_room
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

  def country_name
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end

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

  def location
    "#{institution_location} - #{institution_country}"
  end

  def needed_budget
    tasks.sum(:budget)
  end
end
