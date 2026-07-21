class Api::V3::SyncController < APIController
  include Api::V3::SyncToUser

  def __sync_from_user__(params)
    results = trace_sync_data(
      "merge_batch",
      resource: model.table_name,
      input_count: params.size
    ) do |finish|
      finish[:output_count] = 0
      finish[:error_count] = 0
      finish[:audit_count] = 0
      merge_records(params, finish)
    end

    errors = trace_sync_data(
      "aggregate_validation_results",
      resource: model.table_name
    ) do |finish|
      aggregated_errors = results.flat_map { |result| result[:errors_hash] || [] }
      finish[:error_count] = aggregated_errors.size
      aggregated_errors
    end
    capture_errors params, errors

    trace_sync_data(
      "render_push_response",
      resource: model.table_name
    ) do |finish|
      finish[:error_count] = errors.size
      response = {errors: errors.nil? ? nil : errors}
      render json: response, status: :ok
    end
  end

  def __sync_to_user__(response_key)
    records = trace_sync_data(
      "retrieve_records",
      resource: pull_resource
    ) do |finish|
      retrieved_records = records_to_sync
      finish[:output_count] = retrieved_records.size
      retrieved_records
    end

    unless disable_audit_logs?
      trace_sync_data(
        "enqueue_audit_logs",
        resource: pull_resource,
        input_count: records.size
      ) do |finish|
        result = AuditLog.create_logs_async(current_user, records, "fetch", Time.current)
        finish[:audit_count] = records.size
        result
      end
    end

    transformed_records = trace_sync_data(
      "transform_records",
      resource: pull_resource,
      input_count: records.size
    ) do |finish|
      transformed = records.map { |record| transform_to_response(record) }
      finish[:output_count] = transformed.size
      transformed
    end

    encoded_process_token = trace_sync_data(
      "encode_process_token",
      resource: pull_resource
    ) do
      encode_process_token(response_process_token)
    end

    json = trace_sync_data(
      "serialize_pull_response",
      resource: pull_resource,
      input_count: transformed_records.size
    ) do
      Oj.dump({
        response_key => transformed_records,
        "process_token" => encoded_process_token
      }, mode: :compat)
    end

    trace_sync_data(
      "render_pull_response",
      resource: pull_resource
    ) do |finish|
      finish[:output_count] = transformed_records.size
      render(json: json, status: :ok)
    end
  end

  private

  def model
    controller_name.classify.constantize
  end

  def pull_resource
    model.respond_to?(:table_name) ? model.table_name : controller_name
  end

  def merge_records(params, finish)
    params.flat_map { |single_entity_params|
      begin
        result = merge_if_valid(single_entity_params)
        if result[:record].present?
          finish[:output_count] += 1
          AuditLog.merge_log(current_user, result[:record])
          finish[:audit_count] += 1
        elsif result[:errors_hash].present?
          finish[:error_count] += 1
        end
        result
      rescue
        finish[:record_id] = single_entity_params[:id]
        raise
      end
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
    return @process_token if defined?(@process_token_params) && @process_token_params.equal?(params)

    @process_token_params = params
    @process_token = trace_sync_data(
      "decode_process_token",
      resource: pull_resource
    ) do
      if params[:process_token].present?
        JSON.parse(Base64.decode64(params[:process_token])).with_indifferent_access
      else
        {}
      end
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
