module ApplicationHelper
	def gravatar_for(user, size = 100, title = user.name )
    image_tag gravatar_image_url(user.email, size: size), title: title, class: 'img-rounded'
  end

  def gravatar_for_user(user, size = 30, title = user.name )
    image_tag gravatar_image_url(user.email, size: size), title: title, class: 'img-rounded'
  end

  def gravatar_for_project(project, size = 440, title = project.title )
    image_tag gravatar_image_url(project.title, size: size), title: title, class: 'img-rounded'
  end


   def gravatar_for_projectdisplay(project, size = 200, title = project.title )
    image_tag gravatar_image_url(project.title, size: size), title: title, class: 'img-rounded'
  end

   def gravatar_for_pro(project, size = 30, title = project.title )
    image_tag gravatar_image_url(project.title, size: size), title: title, class: 'img-rounded'
  end

  def landing_page?
    controller.controller_name.eql?('visitors') && !controller.action_name.eql?('landing')
  end

  def landing_class
    'class=landing' if landing_page?
  end
end
