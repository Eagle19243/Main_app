class Project < ActiveRecord::Base
	include AASM
default_scope -> { order('created_at DESC') }
mount_uploader :picture, PictureUploader
mount_uploader :institution_logo, PictureUploader
has_many :tasks, dependent: :destroy
has_many :wikis, dependent: :destroy
has_many :project_comments, dependent: :destroy
belongs_to :user
belongs_to :institution


  def country_name
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end


  aasm :column => 'state', :whiny_transitions => false do

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





end
