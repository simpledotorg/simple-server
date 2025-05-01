# config/initializers/env_defaults.rb

# Database configuration
ENV['SIMPLE_SERVER_DATABASE_HOST']     ||= 'localhost'
ENV['SIMPLE_SERVER_DATABASE_USERNAME'] ||= 'postgres'
ENV['SIMPLE_SERVER_DATABASE_PASSWORD'] ||= 'password'
ENV['SIMPLE_SERVER_DATABASE_NAME']     ||= 'simple-server_test'

# App configuration
ENV['SIMPLE_SERVER_HOST_PROTOCOL'] ||= 'https'
ENV['SIMPLE_SERVER_HOST']          ||= 'localhost'
ENV['SIMPLE_SERVER_ENV']           ||= 'development'
ENV['RAILS_ENV']                   ||= 'production'

# Redis configuration
ENV['CALL_SESSION_REDIS_HOST']      ||= 'redis'
ENV['CALL_SESSION_REDIS_POOL_SIZE'] ||= '12'
ENV['CALL_SESSION_REDIS_TIMEOUT_SEC'] ||= '1'
ENV['RAILS_CACHE_REDIS_URL']        ||= 'redis://'
ENV['RAILS_CACHE_REDIS_PASSWORD']   ||= 'NONE'
ENV['SIDEKIQ_REDIS_HOST']           ||= 'redis'
ENV['SIDEKIQ_CONCURRENCY']          ||= '5'

# Email configuration
ENV['SENDGRID_USERNAME'] ||= 'NONE'
ENV['SENDGRID_PASSWORD'] ||= 'NONE'
ENV['EMAIL_SUBJECT_PREFIX'] ||= '[Simple DEVELOPMENT]'

# Sentry / Error monitoring
ENV['SENTRY_DSN']                     ||= 'none.org'
ENV['SENTRY_SECURITY_HEADER_ENDPOINT'] ||= 'http://none.org'
ENV['SENTRY_CURRENT_ENV']             ||= 'development'

# Seeding configuration
ENV['SEED_GENERATED_ADMIN_PASSWORD'] ||= 'changeme'
ENV['SEED_GENERATED_ACTIVE_USER_ROLE'] ||= 'Seed User | Active'
ENV['SEED_GENERATED_INACTIVE_USER_ROLE'] ||= 'Seed User | Inactive'
ENV['SEED_TYPE'] ||= 'medium'

# Other settings
ENV['DEFAULT_COUNTRY']                ||= 'US'
ENV['DEFAULT_NUMBER_OF_RECORDS']       ||= '10'
ENV['TEMPORARY_RETENTION_DURATION_SECONDS'] ||= '60'
ENV['ANALYTICS_DASHBOARD_CACHE_TTL']   ||= '3600'
ENV['USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES'] ||= '10'

# Help screen YouTube links
ENV['HELP_SCREEN_YOUTUBE_PASSPORT_URL'] ||= 'https://youtu.be/aktZ1yTdDOA'
ENV['HELP_SCREEN_YOUTUBE_TRAINING_URL'] ||= 'https://youtu.be/MC_45DoRw2g'
ENV['HELP_SCREEN_YOUTUBE_VIDEO_URL']    ||= 'https://youtu.be/nHsQ06tiLzw'
ENV['SIMPLE_APP_SIGNATURE'] ||= "test_signature"

ENV['SECRET_KEY_BASE'] ||= '6e3a553d989615581dfdfcfcb0670b002e5d9d27c38a284a5020107e8ba516789117630f9c7e0ade1d0d7b0b68aeb50df88d8b15ea55dc423246db2984f6e5ef'
ENV['TWILIO_ACCOUNT_SID'] ||= '<redacted>'
ENV['TWILIO_AUTH_TOKEN'] ||= '<redacted>'
ENV['TWILIO_PHONE_NUMBER'] ||= '<redacted>'
ENV['TWILIO_REMINDERS_ACCOUNT_SID'] ||= '<redacted>'
ENV['TWILIO_REMINDERS_ACCOUNT_AUTH_TOKEN'] ||= '<redacted>'
ENV['TWILIO_REMINDERS_ACCOUNT_PHONE_NUMBER'] ||= '<redacted>'
ENV['EXOTEL_TOKEN'] ||= '<redacted>'

# Check for critical secrets (warn if missing)
# critical_vars = %w[
#   SECRET_KEY_BASE
#   TWILIO_ACCOUNT_SID
#   TWILIO_AUTH_TOKEN
#   TWILIO_PHONE_NUMBER
#   TWILIO_REMINDERS_ACCOUNT_SID
#   TWILIO_REMINDERS_ACCOUNT_AUTH_TOKEN
#   TWILIO_REMINDERS_ACCOUNT_PHONE_NUMBER
#   EXOTEL_TOKEN
# ]

# critical_vars.each do |var|
#   unless ENV[var].present?
#     Rails.logger.warn("⚠️  Critical environment variable #{var} is missing!")
#   end
# end
