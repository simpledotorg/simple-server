require "simplecov" if ENV["CI"]
require "utils"
require "webmock/rspec"
require "sidekiq/testing"
require "capybara"
require "webdrivers"
require "flipper_helper"

WebMock.allow_net_connect!

RSpec.configure do |config|
  SimpleCov.start if ENV["CI"]

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:each) do
    Rails.cache.clear
    RequestStore.clear!
  end

  Capybara.default_max_wait_time = 5

  Webdrivers::Chromedriver.update

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.register_driver :headless_chrome do |app|
    Capybara::Selenium::Driver.new app, browser: :chrome,
                                        options: Selenium::WebDriver::Chrome::Options.new(args: %w[headless
                                          disable-gpu
                                          window-size=1280,800])
  end

  Capybara.default_driver = :headless_chrome
  Capybara.javascript_driver = :headless_chrome

  config.include FlipperHelpers

  config.before :all do
    # create a Root region and persist across all tests (the Root region is effectively a singleton)
    Region.find_by_name("Root") || Region.create!(name: "Root", region_type: Region.region_types[:root], path: "Root")
  end
end
