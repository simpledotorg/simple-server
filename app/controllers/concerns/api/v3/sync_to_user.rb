module Api::V3::SyncToUser
  extend ActiveSupport::Concern

  included do
    def region_records
      model = controller_name.classify.constantize
      model.syncable_to_region(current_sync_region)
    end

    def current_facility_records
      region_records
        .where(patient: current_facility.syncable_patients)
        .updated_on_server_since(current_facility_processed_since, limit)
    end

    def other_facility_records
      other_facilities_limit = limit - current_facility_records.count

      region_records
        .where.not(patient: current_facility.syncable_patients)
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
      Rails.logger.info "Resync token modified in resource #{controller_name}" if resync_token_modified?
      Rails.logger.info "Sync region modified in resource #{controller_name}" if sync_region_modified?
      resync_token_modified? || sync_region_modified?
    end

    def resync_token_modified?
      process_token[:resync_token] != resync_token
    end

    def sync_region_modified?
      return false if requested_sync_region_id.blank?
      return false if process_token[:sync_region_id].blank?

      process_token[:sync_region_id] != requested_sync_region_id
    end

    def current_sync_region
      # This method selectively permits only FacilityGroup sync (via facility group ID)
      # and block-level sync (via regions) and offers facility group as a safe fallback.
      # Over time, the facility group ID support can be dropped and this method can
      # allow other region types as well
      return current_facility_group if requested_sync_region_id.blank?
      return current_facility_group if requested_sync_region_id == current_facility_group.id
      return current_block if block_level_sync?

      current_facility_group
    end

    def block_level_sync?
      current_user.block_level_sync? && requested_sync_region_id == current_block.id
    end
  end
end
