class Api::V1::SyncController < APIController
  def __sync_from_user__(params)
    errors = params.flat_map do |single_entity_params|
      merge_if_valid(single_entity_params) || []
    end

    response = { errors: errors.nil? ? nil : errors }
    render json: response, status: :ok
  end

  def __sync_to_user__(response_key)
    records_to_sync = find_records_to_sync(processed_since, limit)
    render(
      json:   {
        response_key => records_to_sync.map { |record| transform_to_response(record) },
        'processed_since' => most_recent_record_timestamp(records_to_sync).strftime(TIME_WITHOUT_TIMEZONE_FORMAT)
      },
      status: :ok
    )
  end

  private

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
