class Api::V3::SyncController < APIController
  include Api::V3::SyncToUser
  before_action :instrument_process_token

  def model_name
    controller_name.classify.constantize
  end

  def __sync_from_user__(params)
    errors = params.flat_map { |single_entity_params|
      res = merge_if_valid(single_entity_params)
      AuditLog.merge_log(current_user, res[:record]) if res[:record].present?
      res[:errors_hash] || []
    }

    capture_errors params, errors
    response = {errors: errors.nil? ? nil : errors}
    render json: response, status: :ok
  end

  def __sync_to_user__(response_key)
    AuditLog.create_logs_async(current_user, records_to_sync, "fetch", Time.current) unless disable_audit_logs?
    render(
      json: {
        response_key => records_to_sync.map { |record| transform_to_response(record) },
        "process_token" => encode_process_token(response_process_token)
      },
      status: :ok
    )
  end

  private

  def disable_audit_logs?
    false
  end

  def sync_api_toggled_on?
    FeatureToggle.enabled_for_regex?("MATCHING_SYNC_APIS", controller_name)
  end

  def params_with_errors(params, errors)
    error_ids = errors.map { |error| error[:id] }
    params
      .select { |param| error_ids.include? param[:id] }
      .map(&:to_hash)
  end

  def capture_errors(params, errors)
    return unless errors.present?

    Raven.capture_message(
      "Validation Error",
      logger: "logger",
      extra: {
        params_with_errors: params_with_errors(params, errors),
        errors: errors
      },
      tags: {type: "validation"}
    )
  end

  def process_token
    if params[:process_token].present?
      JSON.parse(Base64.decode64(params[:process_token])).with_indifferent_access
    else
      {}
    end
  end

  def max_limit
    1000
  end

  def limit
    return ENV["DEFAULT_NUMBER_OF_RECORDS"].to_i unless params[:limit].present?
    params_limit = params[:limit].to_i

    params_limit < max_limit ? params_limit : max_limit
  end

  def instrument_process_token
    ::NewRelic::Agent.add_custom_attributes({process_token: process_token})
  end
end
