require 'capybara/rspec'
require 'capybara/rails'

Capybara.ignore_hidden_elements = false

RSpec.configure do |c|
  c.include Capybara::DSL
  c.include(Module.new do
    def click_pseudo_link(text)
      first('a', text: text).click
    end
  end)
end
