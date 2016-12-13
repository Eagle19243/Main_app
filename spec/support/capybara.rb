require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    window_size: [1600, 900],
    screen_size: [1600, 900]
  )
end

Capybara.javascript_driver = :poltergeist
Capybara.ignore_hidden_elements = false

RSpec.configure do |c|
  c.include Capybara::DSL
  c.include(Module.new do
    def click_pseudo_link(text)
      first('a', text: text).click
    end
  end)
end
