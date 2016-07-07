json.array!(@notifications) do |notification|
  json.extract! notification, :id, :type, :summary, :content
  json.url notification_url(notification, format: :json)
end
