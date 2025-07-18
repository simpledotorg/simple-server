class Api::V3::SyncController < APIController
  include Api::V3::SyncToUser

  def __sync_from_user__(params)
    results = merge_records(params)

    errors = results.flat_map { |result| result[:errors_hash] || [] }
    capture_errors params, errors
    response = {errors: errors.nil? ? nil : errors}
    render json: response, status: :ok
  end

  def __sync_to_user__(response_key)
    records = records_to_sync

    AuditLog.create_logs_async(current_user, records, "fetch", Time.current) unless disable_audit_logs?

    transformed_records = records.map { |record| transform_to_response(record) }

    json = Oj.dump({
      response_key => transformed_records,
      "process_token" => encode_process_token(response_process_token)
    }, mode: :compat)

    render(json: json, status: :ok)
  end

  private

  def model
    controller_name.classify.constantize
  end

  def merge_records(params)
    params.flat_map { |single_entity_params|
      result = merge_if_valid(single_entity_params)
      AuditLog.merge_log(current_user, result[:record]) if result[:record].present?
      result
    }
  end

  def disable_audit_logs?
    false
  end

  def params_with_errors(params, errors)
    error_ids = errors.map { |error| error[:id] }
    params
      .select { |param| error_ids.include? param[:id] }
      .map(&:to_hash)
  end

  def errors_hash(record)
    record.errors.to_hash.merge(id: record.id)
  end

  def capture_errors(params, errors)
    return unless errors.present?

    Rails.logger.info(
      msg: "validation_error",
      controller: self.class.name,
      action: action_name,
      params_with_errors: params_with_errors(params, errors),
      errors: errors
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
end
