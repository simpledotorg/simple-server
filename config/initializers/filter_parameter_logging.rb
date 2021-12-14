# We are using a strict approach to parametering filtering for our logs
# to avoid exposing any patient information there. So any attributes
# not explicitly allowed below will be filtered out from the logs.
#
# Be sure to restart your server when you modify this file.
module ParameterFiltering
  ALLOWED_ATTRIBUTES = %w[
    action
    active
    bust_cache
    code
    controller
    created_at
    deleted_at
    district_estimated_population
    for_end_of_month
    limit
    metadata_version
    process_token
    recorded_at
    report_scope
    status
    updated_at
    v2
  ].freeze

  ALLOWED_REGEX = /(^|_)ids?|#{Regexp.union(ALLOWED_ATTRIBUTES)}/.freeze
  # We have to explicitly exclude integer params because
  # the lambda can only filter string params.
  DISALLOWED_INTEGER_PARAMS = [:age, :systolic, :diastolic, :duration_in_days]
  SANITIZED_VALUE = "[FILTERED]".freeze

  # Returns the lambda for attributes that are okay to leave in the logs
  def self.filter
    lambda { |key, value| value.replace(SANITIZED_VALUE) if !key.match(ALLOWED_REGEX) && value.is_a?(String) }
  end
end

Rails.application.config.filter_parameters += [*ParameterFiltering::DISALLOWED_INTEGER_PARAMS, ParameterFiltering.filter]
