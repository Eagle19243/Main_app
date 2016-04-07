class Task < ActiveRecord::Base
	include AASM
	default_scope -> { order('created_at DESC') }
	mount_uploader :fileonee, PictureUploader
	mount_uploader :filetwo, PictureUploader
	mount_uploader :filethree, PictureUploader
	mount_uploader :filefour, PictureUploader
	mount_uploader :filefive, PictureUploader
	belongs_to :project
	belongs_to :user
	has_many :task_comments
	has_many :assignments
	has_many :do_requests
	has_many :donations

	aasm :column => 'state', :whiny_transitions => false do
    state :pending
    state :accepted
    state :rejected      
    end  

	
end
