FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "test_user#{n}@example.com"}
    password 'secretadmin0password'
    sequence(:name) { |n| "Test#{n} User"}
  end

  factory :project do
    sequence(:title) { |n| "test_project#{n}" }
    sequence(:short_description) { |n| "short_description#{n}" }
    sequence(:country) { |n| "test_country#{n}" }
    sequence(:wiki_page_name) { |n| "wiki_page_name#{n}" }
    picture { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'photo.png'), 'image/png') }
    state "pending"

    after(:create) do |project|
      project_team = project.create_team(name: "Team#{project.id}")
      TeamMembership.create(team_member_id: project.user.id, team_id: project_team.id, role:1 )
    end
  end
end