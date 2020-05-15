require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'capybara/rails'
require 'pundit/rspec'
require 'factory_bot_rails'
require 'faker'
require 'timecop'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec/pages/application_page.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec/pages/**/*.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec/**/shared_examples/**/*.rb')].sort.each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # See https://github.com/philostler/rspec-sidekiq/wiki/FAQ-&-Troubleshooting for sidekiq / test info
  config.warn_when_jobs_not_processed_by_sidekiq = false

  config.include ActiveSupport::Testing::TimeHelpers

  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Warden::Test::Helpers

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  config.after :each do
    Warden.test_reset!
  end
end
