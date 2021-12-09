require "rails_helper"
require "capybara"
require "webdrivers"
require "capybara/rails"

Dir[Rails.root.join("spec/pages/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :feature

  config.before(:suite) do
    RefreshReportingViews.call
  end

  config.around(:example, type: :feature) do |example|
    Rails.cache.clear
    example.run
    Rails.cache.clear
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
end
