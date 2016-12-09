class Wiki < ActiveRecord::Base
  acts_as_paranoid

  include AASM
  default_scope -> { order('created_at DESC') }
  mount_uploader :pictureone, PictureUploader
  mount_uploader :picturetwo, PictureUploader
  mount_uploader :picturethree, PictureUploader
  mount_uploader :picturefour, PictureUploader
  mount_uploader :picturefive, PictureUploader
  belongs_to :project

  aasm :column => 'state', :whiny_transitions => false do
    state :pending
    state :accepted
    state :rejected
  end

end
