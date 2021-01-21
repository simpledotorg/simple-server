# We are using a strict approach to parametering filtering for our logs
# to avoid exposing any patient information there. So any attributes
# not explicitly allowed below will be filtered out from the logs.
#
# Be sure to restart your server when you modify this file.
module ParameterFiltering
  ALLOWED_ATTRIBUTES = %w[
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
    report_scope
    status
    updated_at
  ].freeze

  ALLOWED_REGEX = /(^|_)ids?|#{Regexp.union(ALLOWED_ATTRIBUTES)}/.freeze
  SANITIZED_VALUE = "[FILTERED]".freeze

  # Returns the lamba for attributes that are okay to leave in the logs
  def self.filter
    lambda do |key, value|
      unless key.match(ALLOWED_REGEX)
        case value
        when String
          value.replace(SANITIZED_VALUE)
        else
          value.to_s.replace(SANITIZED_VALUE)
        end
      end
    end
  end
end

Rails.application.config.filter_parameters += [:password, :age, ParameterFiltering.filter]
