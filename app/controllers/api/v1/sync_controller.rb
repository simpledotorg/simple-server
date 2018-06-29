class Api::V1::SyncController < APIController
  before_action :check_disabled_api
  before_action :authenticate

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
    records_to_sync = find_records_to_sync(processed_since, limit)

    records_to_sync.each { |record| AuditLog.fetch_log(current_user, record) }
    render(
      json:   {
        response_key      => records_to_sync.map { |record| transform_to_response(record) },
        'processed_since' => most_recent_record_timestamp(records_to_sync).strftime(TIME_WITHOUT_TIMEZONE_FORMAT)
      },
      status: :ok
    )
  end

  private

  def check_disabled_api
    return if sync_api_toggled_on?
    logger.info "Short circuiting #{request.env['PATH_INFO']} since it's a disabled feature"
    head :forbidden
  end

  def sync_api_toggled_on?
    FeatureToggle.enabled_for_regex?('ACCESSIBLE_SYNC_APIS', controller_name)
  end

  def current_user
    @current_user ||= User.find_by(id: request.headers['HTTP_X_USER_ID'])
  end

  def authenticate
    return unless FeatureToggle.enabled?('SYNC_API_AUTHENTICATION')
    return head :unauthorized unless authenticated?
    current_user.mark_as_logged_in if current_user.has_never_logged_in?
  end

  def authenticated?
    current_user.present? && current_user.access_token_valid? && access_token_authorized?
  end

  def access_token_authorized?
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, current_user.access_token)
    end
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
      extra:  {
        params_with_errors: params_with_errors(params, errors),
        errors:             errors
      },
      tags:   { type: 'validation' }
    )
  end

  def most_recent_record_timestamp(records_to_sync)
    if records_to_sync.empty?
      processed_since
    else
      records_to_sync.last.updated_at
    end
  end

  def processed_since
    params[:processed_since].try(:to_time) || Time.new(0)
  end

  def limit
    if params[:limit].present?
      params[:limit].to_i
    else
      ENV['DEFAULT_NUMBER_OF_RECORDS'].to_i
    end
  end
end
