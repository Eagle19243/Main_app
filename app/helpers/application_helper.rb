module ApplicationHelper
	def gravatar_for(user, size = 100, title = user.name )
    image_tag gravatar_image_url(user.email, size: size), title: title, class: 'img-rounded'
  end
  def gravatar_for_fund(user, size = 44, title = user.name )
    image_tag gravatar_image_url(user.email, size: size), title: title, class: 'modal-fund__avatar'
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

  def get_reserve_wallet_balance
    reserve_wallet_id = ENV['reserve_wallet_id'].to_s.strip
    return 0 if reserve_wallet_id.blank?

    api = Bitgo::V1::Api.new
    wallet = api.get_wallet(wallet_id: reserve_wallet_id, access_token: Payments::BTC::Base.bitgo_reserve_access_token)
    wallet["balance"]
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

  def convert_btc_to_satoshi(btc)
    satoshi_amount = btc.to_f * (10 ** 8)
    satoshi_amount.to_i
  end

  def convert_satoshi_to_btc(satoshi)
     satoshi.to_f/10**8.to_f
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

  def btc_balance(btc)
    btc.to_f.round(4)
  end

  def satoshi_balance_in_btc(satoshi)
    satoshi_to_btc = satoshi.to_f/10**8.to_f
    satoshi_to_btc.round(4)
  end

  def satoshi_balance_in_usd(satoshi)
    satoshi_to_btc = satoshi.to_f/10**8.to_f
    btc_to_usd =  satoshi_to_btc * get_current_btc_rate
    btc_to_usd.round(3)
  end

  def min_fund_budget_in_btc
    satoshi_balance_in_btc(Task::MINIMUM_FUND_BUDGET)
  end

  def projects_taskstab?
    controller_name == 'projects' && action_name == 'taskstab'
  end

 def active_class(link_path)
  current_page?(link_path) ? "active" : ""
 end

end
