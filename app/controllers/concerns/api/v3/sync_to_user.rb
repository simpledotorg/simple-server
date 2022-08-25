module Api::V3::SyncToUser
  extend ActiveSupport::Concern

  included do
    private

    def model_sync_scope
      model.for_sync
    end

    def records_to_sync
      @records_to_sync ||=
        model_sync_scope
          .where(patient: current_sync_region.syncable_patients)
          .updated_on_server_since(processed_since, limit)
    end

    def processed_until(records)
      records.last.updated_at.strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT) if records.any?
    end

    def response_process_token
      {
        current_facility_id: current_facility.id,
        processed_since: processed_until(records_to_sync) || processed_since,
        resync_token: resync_token,
        sync_region_id: current_sync_region.id
      }
    end

    def encode_process_token(process_token)
      Base64.encode64(process_token.to_json)
    end

    def processed_since
      return Time.new(0) if force_resync?

      process_token[:processed_since].try(:to_time) ||
        [process_token[:other_facilities_processed_since].try(:to_time),
         process_token[:current_facilities_processed_since].try(:to_time)].compact.min ||
        Time.new(0)
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
