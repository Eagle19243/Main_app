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

  def access_wallet
    begin
      settings = YAML.load_file("#{Rails.root}/config/application.yml")
      response = RestClient.get  "http://localhost:3080/api/v1/ping"
      unless response.blank?
        api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
        access_token = settings['bitgo_admin']['access_token']
      end
    rescue => e
      Rails.logger.info e.message
    end
  end
  
  def get_current_btc_rate
    begin
      response ||= RestClient.get 'https://www.bitstamp.net/api/ticker/'
       btc=JSON.parse(response)['last'] rescue 0.0
      btc.to_f
    rescue => e
      "error"
    end
  end



end
