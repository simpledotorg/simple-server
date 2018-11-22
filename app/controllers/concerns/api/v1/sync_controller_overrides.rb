module Api::V1::SyncControllerOverrides
  extend ActiveSupport::Concern

  included do
    def model_name
      controller_name.classify.constantize
    end

    def __sync_to_user__(response_key)
      records_to_sync = find_records_to_sync(processed_since, limit)
      records_to_sync.each { |record| AuditLog.fetch_log(current_user, record) }
      render(
        json: {
          response_key => records_to_sync.map { |record| transform_to_response(record) },
          'processed_since' => most_recent_record_timestamp(records_to_sync).strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT)
        },
        status: :ok
      )
    end

    def find_records_to_sync(since, limit)
      model_name.updated_on_server_since(since, limit)
    end

    def processed_since
      params[:processed_since].try(:to_time) || Time.new(0)
    end

    def most_recent_record_timestamp(records_to_sync)
      if records_to_sync.empty?
        processed_since
      else
        records_to_sync.last.updated_at
      end
    end
  end
end
