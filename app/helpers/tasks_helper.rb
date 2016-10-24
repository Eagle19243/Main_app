module TasksHelper

	def freelancers_options
    s = ''
    User.all.each do |user|
      s << "<option value='#{user.id}' data-img-src='#{gravatar_image_url(user.email, size: 50)}'>#{user.name}</option>"
    end
    s.html_safe
  end


 def  get_activity_detail(activity)
   if (activity.targetable_type == "Task")
     if (activity.action == "created")
       return ( " created this task .")
     end
     if (activity.action == "edited")
       return ( " updated this task .")
     end
   end
   if(activity.targetable_type == "TaskComment")
     return (" commented on this task .")
   end

 end
end
