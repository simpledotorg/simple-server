require "faker"

Faker::Config.locale = Rails.application.config.country["faker_locale"]
