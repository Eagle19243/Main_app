class Task < ActiveRecord::Base
	include AASM
	default_scope -> { order('created_at DESC') }
	mount_uploader :fileone, PictureUploader
	mount_uploader :filetwo, PictureUploader
	mount_uploader :filethree, PictureUploader
	mount_uploader :filefour, PictureUploader
	mount_uploader :filefive, PictureUploader
	belongs_to :project
	belongs_to :user
	has_many :task_comments, dependent: :delete_all
	has_many :assignments, dependent: :delete_all
	has_many :do_requests, dependent: :delete_all
	has_many :donations, dependent: :delete_all
	aasm :column => 'state', :whiny_transitions => false do
    state :pending
    state :accepted
    state :rejected      
    end  
    validates :proof_of_execution, presence: true
    validates :title, presence: true, length: { minimum: 2, maximum: 30 }
    validates :condition_of_execution, presence: true
    validates :short_description, presence: true, length: { minimum: 20, maximum: 100 }             
    validates :description, presence: true 
    validates_numericality_of :budget, :only_integer => false, :greater_than_or_equal_to => 1
    validates :budget, presence: true
   
    validates :target_number_of_participants, presence: true
    validates_numericality_of :target_number_of_participants, :only_integer => true, :greater_than_or_equal_to => 1
	
end
