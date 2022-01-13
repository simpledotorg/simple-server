# See https://app.clubhouse.io/simpledotorg/story/1616/why-do-heroku-deployments-intermittently-fail
unless SimpleServer.env.review? && Rake.application.top_level_tasks.any? { |task| task.include?("assets") }
  Config.ensure_required_keys_are_present(required_keys: [
    "SENTRY_SECURITY_HEADER_ENDPOINT",
    "TEMPORARY_RETENTION_DURATION_SECONDS"
  ])
end

Config.ensure_required_keys_are_present(required_keys: [
  "DEFAULT_NUMBER_OF_RECORDS",
  "DEFAULT_COUNTRY",
  "SIMPLE_APP_SIGNATURE",
  "SENDGRID_USERNAME",
  "SENDGRID_PASSWORD",
  "SENTRY_DSN",
  "SENTRY_CURRENT_ENV",
  "TWILIO_ACCOUNT_SID",
  "TWILIO_AUTH_TOKEN",
  "TWILIO_PHONE_NUMBER",
  "USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES",
  "EMAIL_SUBJECT_PREFIX",
  "SIMPLE_SERVER_ENV",
  "SIMPLE_SERVER_HOST",
  "SIMPLE_SERVER_HOST_PROTOCOL",
  "CALL_SESSION_REDIS_POOL_SIZE",
  "CALL_SESSION_REDIS_TIMEOUT_SEC",
  "HELP_SCREEN_YOUTUBE_VIDEO_URL",
  "HELP_SCREEN_YOUTUBE_PASSPORT_URL",
  "HELP_SCREEN_YOUTUBE_TRAINING_URL",
  "RAILS_CACHE_REDIS_PASSWORD",
  "SIDEKIQ_CONCURRENCY",
  "ANALYTICS_DASHBOARD_CACHE_TTL"
])

Config.ensure_required_keys_have_fallbacks(required_keys: {
  "CALL_SESSION_REDIS_HOST" => "REDIS_URL",
  "SIDEKIQ_REDIS_HOST" => "REDIS_URL",
  "RAILS_CACHE_REDIS_URL" => "REDIS_URL"
})
