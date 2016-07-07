json.array!(@teams) do |team|
  json.extract! team, :id, :name, :number_of_members, :number_of_projects, :mission
  json.url team_url(team, format: :json)
end
