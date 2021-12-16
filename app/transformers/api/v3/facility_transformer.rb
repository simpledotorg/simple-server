class Api::V3::FacilityTransformer
  class << self
    def to_response(facility)
      facility.as_json
        .except("enable_diabetes_management",
          "monthly_estimated_opd_load",
          "enable_teleconsultation",
          "teleconsultation_phone_number",
          "teleconsultation_isd_code",
          "teleconsultation_phone_numbers",
          "organization_name",
          "facility_group_name")
        .merge(config: {enable_diabetes_management: facility.enable_diabetes_management,
                        enable_teleconsultation: facility.enable_teleconsultation},
          protocol_id: facility.protocol.try(:id))
    end
  end
end
