json.array!(@institution_users) do |institution_user|
  json.extract! institution_user, :id, :institution_id, :user_id, :position
  json.url institution_user_url(institution_user, format: :json)
end
