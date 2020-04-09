require 'simplecov'
require 'utils'
require 'webmock/rspec'
require 'fakeredis/rspec'
require 'sidekiq/testing'
require 'capybara'
require 'webdrivers'

WebMock.allow_net_connect!

RSpec.configure do |config|
  SimpleCov.start

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:each) do
    Rails.cache.clear
  end

  Capybara.default_max_wait_time = 5

  Webdrivers::Chromedriver.update

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.register_driver :headless_chrome do |app|
    Capybara::Selenium::Driver.new app, browser: :chrome,
                                   options: Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu])
  end

  Capybara.default_driver = :headless_chrome
  Capybara.javascript_driver = :headless_chrome

  # Capybara.default_driver = :chrome
  # Capybara.javascript_driver = :chrome
end
