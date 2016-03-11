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

  has_many :projects, dependent: :destroy
  has_many :project_comments, dependent: :destroy
  has_many :activities
  belongs_to :institution 
  has_many :do_requests
  has_many :do_for_frees
  has_many :assignments


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
    assignment
  end





end
