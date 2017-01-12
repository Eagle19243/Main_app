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
    controller.controller_name.eql?('visitors') && controller.action_name.eql?('landing')
  end

  def landing_class
    'class=landing' if landing_page?
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
      Rails.logger.info "BITCOIN ERROR: #{e.message}" unless Rails.env == "development"
    end
  end


  def we_serve_wallet
    begin
      settings = YAML.load_file("#{Rails.root}/config/application.yml")
      response = RestClient.get  "http://localhost:3080/api/v1/ping"
      unless response.blank?
        api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
        access_token = settings['bitgo_admin']['weserve_admin_access_token']
      end
    rescue => e
      Rails.logger.info "BITCOIN ERROR: #{e.message}" unless Rails.env == "development"
    end
  end

  def convert_usd_to_btc_and_then_satoshi(usd)
    begin
      response ||= RestClient.get 'https://www.bitstamp.net/api/ticker/'
      @get_current_rate = JSON.parse(response)['last'] rescue 0.0
      usd_to_btc = (usd.to_f/@get_current_rate.to_f)
      satoshi_amount = usd_to_btc.to_f * (10 ** 8)
      satoshi_amount = satoshi_amount.to_i
    rescue => e
      "error"
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
  def  curent_bts_to_usd(id)
    satoshi_to_btc = Task.find(id).wallet_address.current_balance.to_f/10**8.to_f
    btc_to_usd = satoshi_to_btc * get_current_btc_rate
    btc_to_usd.round(3)
  end

  def  user_wallet_balance_btc( satoshi )
    satoshi_to_btc = satoshi.to_f/10**8.to_f
    satoshi_to_btc.round(4)
  end

  def user_wallet_balance_usd( satoshi )
    satoshi_to_btc = satoshi.to_f/10**8.to_f
    btc_to_usd =  satoshi_to_btc * get_current_btc_rate
    btc_to_usd.round(3)
  end

  def projects_taskstab?
    controller_name == 'projects' && action_name == 'taskstab'
  end

 def active_class(link_path)
  current_page?(link_path) ? "active" : ""
 end

end
