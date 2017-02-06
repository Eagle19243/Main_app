FactoryGirl.define do
  factory :base_project, class: Project do
    title Faker::Lorem.words(4)
    state 'pending'
    short_description Faker::Lorem.words(4)
    association :user, factory: :user
    wiki_page_name Faker::Lorem.words(3)
    picture { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'photo.png'), 'image/png') }
  end
end
