module Api::Current::SyncToUser
  extend ActiveSupport::Concern
  included do
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
      records.last.updated_at.strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT) if records.present?
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
  end
end
