FactoryGirl.define do
  factory :user do
    email 'test_user@example.com'
    password 'secretadmin0password'
    name 'Test0 User'
  end

  factory :project do
    title 'test_project'
    short_description 'short_description'
    country 'test_country'
    wiki_page_name 'wiki_page_name'
    picture { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'photo.png'), 'image/png') }
  end
end