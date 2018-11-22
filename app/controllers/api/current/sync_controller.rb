class Api::Current::SyncController < APIController
  before_action :check_disabled_api

  def model_name
    controller_name.classify.constantize
  end

  def __sync_from_user__(params)
    errors = params.flat_map do |single_entity_params|
      res = merge_if_valid(single_entity_params)
      AuditLog.merge_log(current_user, res[:record]) if res[:record].present?
      res[:errors_hash] || []
    end

    capture_errors params, errors
    response = { errors: errors.nil? ? nil : errors }
    render json: response, status: :ok
  end

  def __sync_to_user__(response_key)
    records_to_sync.each { |record| AuditLog.fetch_log(current_user, record) }
    render(
      json: {
        response_key => records_to_sync.map { |record| transform_to_response(record) },
        'process_token' => encode_process_token(response_process_token)
      },
      status: :ok
    )
  end

  def current_facility_records
    []
  end

  def other_facility_records
    other_facilities_limit = limit - current_facility_records.count
    model_name
      .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
  end

  private

  def records_to_sync
    current_facility_records + other_facility_records
  end

  def processed_until(records)
    records.last.updated_at.strftime(TIME_WITHOUT_TIMEZONE_FORMAT) if records.present?
  end

  def response_process_token
    { current_facility_id: current_facility.id,
      current_facility_processed_since: processed_until(current_facility_records) || current_facility_processed_since,
      other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since }
  end

  def encode_process_token(process_token)
    Base64.encode64(process_token.to_json)
  end

  def other_facilities_processed_since
    process_token[:other_facilities_processed_since].try(:to_time) || Time.new(0)
  end

  def current_facility_processed_since
    if process_token[:current_facility_processed_since].blank?
      other_facilities_processed_since
    elsif process_token[:current_facility_id] != current_facility.id
      [process_token[:current_facility_processed_since].to_time, other_facilities_processed_since].min
    else
      process_token[:current_facility_processed_since].to_time
    end
  end

  def check_disabled_api
    return if sync_api_toggled_on?
    logger.info "Short circuiting #{request.env['PATH_INFO']} since it's a disabled feature"
    head :forbidden
  end

  def sync_api_toggled_on?
    FeatureToggle.enabled_for_regex?('MATCHING_SYNC_APIS', controller_name)
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
      'Validation Error',
      logger: 'logger',
      extra: {
        params_with_errors: params_with_errors(params, errors),
        errors: errors
      },
      tags: { type: 'validation' }
    )
  end

  def process_token
    if params[:process_token].present?
      JSON.parse(Base64.decode64(params[:process_token])).with_indifferent_access
    else
      {}
    end
  end

  def limit
    if params[:limit].present?
      params[:limit].to_i
    else
      ENV['DEFAULT_NUMBER_OF_RECORDS'].to_i
    end
  end
end
