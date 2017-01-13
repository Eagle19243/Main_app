require 'rest-client'
require 'json'

Rails.application.configure do
  # Extract credentials
  settings = YAML.load_file("#{Rails.root}/config/application.yml")
  lgusername = settings['mediawiki']['username']
  lgpassword = settings['mediawiki']['password']
  api_base_url = settings['mediawiki']['api_base_url']
  # Fetch login token
  response = RestClient.get("#{api_base_url}api.php?action=query&meta=tokens&type=login&format=json")
  # Save cookies
  cookies = response.cookies
  # Extract token
  token = JSON.parse(response)['query']['tokens']['logintoken']

  # Do a login
  result = RestClient.post("#{api_base_url}api.php?action=login",
    {
      lgname: lgusername,
      lgpassword:lgpassword,
      lgtoken: token,
      format: 'json'
    },
    {
      :cookies => cookies
    }
  )
  # Save session cookies
  config.mediawiki_session = result.cookies
end