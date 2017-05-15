module ApplicationHelper
  def gravatar_for_user(user, size = 30, title = user.display_name )
    image_tag t('commons.default_user_pic'), size: size.to_s + 'x' + size.to_s, title: title, class: 'img-rounded'
  end

  def gravatar_for_project(project, size = 440, title = project.title )
    image_tag gravatar_image_url(project.title, size: size), title: title, class: 'img-rounded'
  end

  def landing_page?
    controller.controller_name.eql?('visitors') && controller.action_name.eql?('landing')
  end

  def landing_class
    'class=landing' if landing_page?
  end
  
  def btc_balance(btc)
    btc.to_f.round(4)
  end

  def satoshi_balance_in_btc(satoshi)
    Payments::BTC::Converter.convert_satoshi_to_btc(satoshi).round(4)
  end

  def satoshi_balance_in_usd(satoshi)
    Payments::BTC::Converter.convert_satoshi_to_usd(satoshi).round(3)
  end

  def min_fund_budget_in_btc
    satoshi_balance_in_btc(Task::MINIMUM_FUND_BUDGET)
  end

  def min_transfer_amount_in_btc
    satoshi_balance_in_btc(Payments::BTC::FundBtcAddress::MIN_AMOUNT)
  end

  def projects_taskstab?
    controller_name == 'projects' && action_name == 'taskstab'
  end

 def active_class(link_path)
   current_page?(link_path) ? "active" : ""
 end

end
