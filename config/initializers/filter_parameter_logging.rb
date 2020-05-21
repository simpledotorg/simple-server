# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password, :age]

WHITELISTED_KEYS_MATCHER = /((^|_)ids?|action|controller|code|created_at|updated_at|recorded_at|deleted_at|limit|process_token$)/.freeze
SANITIZED_VALUE = '[FILTERED]'.freeze

Rails.application.config.filter_parameters << lambda do |key, value|
  unless key.match(WHITELISTED_KEYS_MATCHER)
    case value
    when String
      value.replace(SANITIZED_VALUE)
    when Integer
      value = SANITIZED_VALUE
    end
  end
end
