module SpecTestHelpers
 	def wait_for_ajax
 		Timeout.timeout(Capybara.default_max_wait_time) do
    	loop until finished_all_ajax_requests?
    end
  end
  
  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

  def set_omniauth(credentials)
    provider = credentials.provider

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider] = credentials
    
    PictureUploader.any_instance.stub(:download!)
  end
end

RSpec.configure do |config|
  config.include SpecTestHelpers, type: :feature
end