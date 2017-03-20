require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|

  options = {
      :window_size => [1600, 900],
      :screen_size => [1600, 900],
      :timeout => 120
  }

  Capybara::Poltergeist::Driver.new(app, options)
end

Capybara.javascript_driver = :poltergeist
Capybara.ignore_hidden_elements = false
Capybara.server_port = 35792
Capybara.default_max_wait_time = 120

RSpec.configure do |c|
  c.include Capybara::DSL
  c.include(Module.new do
    def click_pseudo_link(text)
      first('a', text: text).click
    end
  end)
end
