class Api::V3::FacilityTransformer
  class << self
    def to_response(facility)
      facility.as_json
        .except("enable_diabetes_management",
          "monthly_estimated_opd_load",
          "enable_teleconsultation",
          "teleconsultation_phone_number",
          "teleconsultation_isd_code",
          "teleconsultation_phone_numbers")
        .merge(config: {enable_diabetes_management: facility.enable_diabetes_management,
          enable_teleconsultation: facility.enable_teleconsultation},
          sync_region_id: sync_region_id(facility),
          protocol_id: facility.protocol.try(:id))
    end

    def sync_region_id(facility)
      if current_user.feature_enabled?(:region_level_sync)
        facility.region.block.id
      else
        facility.facility_group.id
      end
    end
  end
end
