require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"

require_relative "../lib/extensions/logging_extensions"
require_relative "../lib/env_helper"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SimpleServer
  class Application < Rails::Application
    # Set our "app environment" as early as possible here
    Object.const_set(:SIMPLE_SERVER_ENV, ENV["SIMPLE_SERVER_ENV"])

    console do
      # Colors don't work right in console with our logging, so turn them off
      config.colorize_logging = false
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.generators do |g|
      g.system_tests false
      g.helper false
    end

    config.active_record.schema_format = :sql
    config.autoload_paths += %W[#{config.root}/lib]

    # Locale configuration
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.available_locales = %w[am-ET bn-BD bn-IN en en-IN es hi-IN kn-IN mr-IN om-ET pa-Guru-IN si-LK sid-ET so-ET ta-IN ta-LK te-IN ti-ET]
    config.i18n.fallbacks = [:en]
    config.i18n.default_locale = :en

    require "json_logger"
    config.log_formatter = LoggingExtensions.default_log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(JsonLogger.new(Rails.root.join("log", "#{Rails.env}.log")))
  end
end
