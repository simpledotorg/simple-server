require "rails_helper"
require "capybara"
require "webdrivers"
require "capybara/rails"
require "capybara/selenium/driver"

Dir[Rails.root.join("spec/pages/**/*.rb")].sort.each { |f| require f }

# Capybara 3.39's ChromeDriver#reset! clears storage with
# Storage.clearDataForOrigin(origin: "*"). Newer Chrome releases reject "*"
# with "invalid argument: * is not a valid URL", which fails whichever feature
# spec happens to run on an agent with a newer Chrome. Newer Capybara releases
# need Ruby 3, so until we upgrade, clear cookies globally and clear the app
# server's origin explicitly. Remove this once Capybara is upgraded.
module ChromeResetWithExplicitOrigin
  def reset!
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError => e
    raise unless e.message.include?("is not a valid URL")

    execute_cdp("Network.clearBrowserCookies")
    origin = Capybara.current_session.server&.base_url
    execute_cdp("Storage.clearDataForOrigin", origin: origin, storageTypes: storage_types_to_clear) if origin
  end
end
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetWithExplicitOrigin)

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
