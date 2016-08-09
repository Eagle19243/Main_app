class User < ActiveRecord::Base
  enum role: [:user, :vip, :admin, :manager, :moderator]
  after_initialize :set_default_role, :if => :new_record?
  def set_default_role
    self.role ||= :user
  end
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  mount_uploader :picture, PictureUploader
  after_create :populate_guid_and_token
  has_many :projects, dependent: :destroy
  has_many :project_edits, dependent: :destroy
  has_many :project_comments, dependent: :delete_all
  has_many :activities, dependent: :delete_all
  belongs_to :institution
  has_many :do_requests, dependent: :delete_all
  has_many :do_for_frees
  has_many :assignments, dependent: :delete_all
  has_many :donations
  has_many :proj_admins, dependent: :delete_all
  # a user can belong to many institutions, the join table for this has been named :institution_users
  has_many :institution_users
  has_many :institutions, :through => :institution_users
  # users can send each other profile comments
  has_many :profile_comments, foreign_key: "receiver_id", dependent: :destroy

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
end
