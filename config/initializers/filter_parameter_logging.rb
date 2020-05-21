# Be sure to restart your server when you modify this file.
module ParameterFiltering
  ATTRIBUTE_WHITELIST = %w[
    action
    active
    code
    controller
    created_at
    deleted_at
    limit
    metadata_version
    process_token
    recorded_at
    status
    updated_at
  ].freeze

  WHITELIST_REGEX = /(^|_)ids?|#{Regexp.union(ATTRIBUTE_WHITELIST)}/.freeze
  SANITIZED_VALUE = "[FILTERED]".freeze
end

Rails.application.config.filter_parameters += [:password, :age]
Rails.application.config.filter_parameters << lambda do |key, value|
  unless key.match(ParameterFiltering::WHITELIST_REGEX)
    case value
    when String
      value.replace(ParameterFiltering::SANITIZED_VALUE)
    else
      value.to_s.replace(ParameterFiltering::SANITIZED_VALUE)
    end
  end
end
