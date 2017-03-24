FactoryGirl.define do
  factory :team_membership, class: TeamMembership do
    role        { 'leader' }
    team        { build(:team) }
    team_member { build(:user) }

    trait :teammate do
      role    { 'teammate' }
    end

    trait :lead_editor do
      role    { 'lead_editor' }
    end

    trait :executor do
      role    { 'executor' }
    end
  end
end
