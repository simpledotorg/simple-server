# Apply environment variable defaults only when running the prebuilt Docker image in production mode.
# This ensures:
# 1. Open-source users who pull the Docker image can run it immediately with sensible defaults.
# 2. Real production deployments (e.g., AWS, Heroku) are unaffected.
# 3. Development and test environments are not polluted with these values.

return unless Rails.env.production?
return unless ENV["DOCKERIZED"] == "true"

# Database configuration
ENV["SIMPLE_SERVER_DATABASE_HOST"] ||= "localhost"
ENV["SIMPLE_SERVER_DATABASE_USERNAME"] ||= "postgres"
ENV["SIMPLE_SERVER_DATABASE_PASSWORD"] ||= "password"
ENV["SIMPLE_SERVER_DATABASE_NAME"] ||= "simple-server_test"

# App configuration
ENV["SIMPLE_SERVER_HOST_PROTOCOL"] ||= "https"
ENV["SIMPLE_SERVER_HOST"] ||= "localhost"
ENV["SIMPLE_SERVER_ENV"] ||= "production"
ENV["RAILS_ENV"] ||= "production"

# Redis configuration
ENV["CALL_SESSION_REDIS_HOST"] ||= "redis"
ENV["CALL_SESSION_REDIS_POOL_SIZE"] ||= "12"
ENV["CALL_SESSION_REDIS_TIMEOUT_SEC"] ||= "1"
ENV["RAILS_CACHE_REDIS_URL"] ||= "redis://localhost:6379/0"
ENV["RAILS_CACHE_REDIS_PASSWORD"] ||= "NONE"
ENV["SIDEKIQ_REDIS_HOST"] ||= "redis"
ENV["SIDEKIQ_CONCURRENCY"] ||= "5"

# Email configuration
ENV["SENDGRID_USERNAME"] ||= "NONE"
ENV["SENDGRID_PASSWORD"] ||= "NONE"
ENV["EMAIL_SUBJECT_PREFIX"] ||= "[Simple DEVELOPMENT]"

# Sentry / Error monitoring
ENV["SENTRY_DSN"] ||= "none.org"
ENV["SENTRY_SECURITY_HEADER_ENDPOINT"] ||= "http://none.org"
ENV["SENTRY_CURRENT_ENV"] ||= "development"

# Seeding configuration
ENV["SEED_GENERATED_ADMIN_PASSWORD"] ||= "changeme"
ENV["SEED_GENERATED_ACTIVE_USER_ROLE"] ||= "Seed User | Active"
ENV["SEED_GENERATED_INACTIVE_USER_ROLE"] ||= "Seed User | Inactive"
ENV["SEED_TYPE"] ||= "medium"

# Other settings
ENV["DEFAULT_COUNTRY"] ||= "US"
ENV["DEFAULT_NUMBER_OF_RECORDS"] ||= "10"
ENV["TEMPORARY_RETENTION_DURATION_SECONDS"] ||= "60"
ENV["ANALYTICS_DASHBOARD_CACHE_TTL"] ||= "3600"
ENV["USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES"] ||= "10"

# Help screen YouTube links
ENV["HELP_SCREEN_YOUTUBE_PASSPORT_URL"] ||= "https://youtu.be/aktZ1yTdDOA"
ENV["HELP_SCREEN_YOUTUBE_TRAINING_URL"] ||= "https://youtu.be/MC_45DoRw2g"
ENV["HELP_SCREEN_YOUTUBE_VIDEO_URL"] ||= "https://youtu.be/nHsQ06tiLzw"
ENV["SIMPLE_APP_SIGNATURE"] ||= "test_signature"

# Secrets (only for demo use!)
ENV["SECRET_KEY_BASE"] ||= "b90c991f1987f5be558af41e1fdc73741adbef2285f30a5bd500dcd7804b2ef1b49e8b07e03bd7154dcecd5050102f0f59cd182c8b40e48a66d416228dbd33fe"

# Twilio / Exotel credentials (use real creds in actual production)
ENV["TWILIO_ACCOUNT_SID"] ||= "<redacted>"
ENV["TWILIO_AUTH_TOKEN"] ||= "<redacted>"
ENV["TWILIO_PHONE_NUMBER"] ||= "<redacted>"
ENV["TWILIO_REMINDERS_ACCOUNT_SID"] ||= "<redacted>"
ENV["TWILIO_REMINDERS_ACCOUNT_AUTH_TOKEN"] ||= "<redacted>"
ENV["TWILIO_REMINDERS_ACCOUNT_PHONE_NUMBER"] ||= "<redacted>"
ENV["EXOTEL_TOKEN"] ||= "<redacted>"
