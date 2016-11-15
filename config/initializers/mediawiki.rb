require 'rest-client'
require 'json'

Rails.application.configure do
  # Fetch login token
  response = RestClient.get('http://wiki.weserve.io/api.php?action=query&meta=tokens&type=login&format=json')
  # Save cookies
  cookies = response.cookies
  # Extract token
  token = JSON.parse(response)['query']['tokens']['logintoken']
  # Extract credentials
  settings = YAML.load_file("#{Rails.root}/config/application.yml")
  lgusername = settings['mediawiki']['username']
  lgpassword = settings['mediawiki']['password']

  # Do a login
  result = RestClient.post('http://wiki.weserve.io/api.php?action=login',
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