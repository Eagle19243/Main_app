class MessagesController < ApplicationController

 before_action :authenticate_user!
 layout false

 def index
  project_ids= Array.[]
  all_Assignments =current_user.assignments.all
  all_Assignments.each do |ass|
   task = Task.find(ass.task_id)
   project_ids << task.project_id
  end
  project_ids = project_ids.uniq
  @projects= current_user.projects|Project.where(id: project_ids)
   puts ''
 end

  def create_chat_room
  end
end