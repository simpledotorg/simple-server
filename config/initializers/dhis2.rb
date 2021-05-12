Dhis2.configure do |config|
  config.url = ENV.fetch("DHIS2_URL")
  config.user = ENV.fetch("DHIS2_USERNAME")
  config.password = ENV.fetch("DHIS2_PASSWORD")
  config.version = ENV.fetch("DHIS2_VERSION")
end
