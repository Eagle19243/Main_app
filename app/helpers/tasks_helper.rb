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
       return ( " This task was proposed by ")
     end
     if (activity.action == "edited")
       return ( " This task was edited by ")
     end
   end
   if(activity.targetable_type == "TaskComment")
     return (" This task was commented by ")
   end

 end
end
