# frozen_string_literal: true

module Api::V3::SyncToUser
  extend ActiveSupport::Concern

  included do
    def current_facility_records
      time(__method__) do
        @current_facility_records ||=
          model_sync_scope
            .where(patient: current_facility.prioritized_patients.select(:id))
            .updated_on_server_since(current_facility_processed_since, limit)
      end
    end

    # this is performance-critical code, be careful while refactoring it
    def other_facility_records
      time(__method__) do
        other_facilities_limit = limit - current_facility_records.size
        @other_facility_records ||=
          model_sync_scope
            .where("patient_id = ANY (array(?))",
              current_sync_region
                .syncable_patients
                .where.not(registration_facility: current_facility)
                .select(:id))
            .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
      end
    end

    private

    def model_sync_scope
      model.for_sync
    end

    def records_to_sync
      current_facility_records + other_facility_records
    end

    def processed_until(records)
      records.last.updated_at.strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT) if records.any?
    end

    def response_process_token
      {
        current_facility_id: current_facility.id,
        current_facility_processed_since: processed_until(current_facility_records) || current_facility_processed_since,
        other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since,
        resync_token: resync_token,
        sync_region_id: current_sync_region.id
      }
    end

    def encode_process_token(process_token)
      Base64.encode64(process_token.to_json)
    end

    def other_facilities_processed_since
      return Time.new(0) if force_resync?
      process_token[:other_facilities_processed_since].try(:to_time) || Time.new(0)
    end

    def current_facility_processed_since
      if force_resync?
        Time.new(0)
      elsif process_token[:current_facility_processed_since].blank?
        other_facilities_processed_since
      elsif process_token[:current_facility_id] != current_facility.id
        [process_token[:current_facility_processed_since].to_time,
          other_facilities_processed_since].min
      else
        process_token[:current_facility_processed_since].to_time
      end
    end

    def force_resync?
      resync_token_modified? || sync_region_modified?
    end

    def resync_token_modified?
      process_token[:resync_token] != resync_token
    end

    def sync_region_modified?
      # If the user has been syncing a different region than
      # what we think the user's sync region should be, we resync.
      return if process_token[:sync_region_id].blank?
      process_token[:sync_region_id] != current_sync_region.id
    end

    def time(method_name, &block)
      raise ArgumentError, "You must supply a block" unless block

      Statsd.instance.time("#{method_name}.#{model.name}") do
        yield(block)
      end
    end
  end
end
