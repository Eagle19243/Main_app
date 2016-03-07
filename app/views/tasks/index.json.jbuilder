json.array!(@tasks) do |task|
  json.extract! task, :id, :references, :title, :description, :budget
  json.url task_url(task, format: :json)
end
