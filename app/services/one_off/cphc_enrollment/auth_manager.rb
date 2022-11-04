class OneOff::CphcEnrollment::AuthManager
  attr_reader :facility

  def initialize(facility)
    @facility = facility
  end

  def user
    mapping = CphcFacilityMapping.with_user(facility)
    cphc_type = OneOff::CphcEnrollment::FACILITY_TYPE_MAPPING[facility.facility_type]
    {user_id: mapping.cphc_user_details["user_id"],
     facility_type_id: OneOff::CphcEnrollment::FACILITY_TYPE_ID[cphc_type],
     state_code: mapping.cphc_state_id}
  end

  def create_user
    if facility.cphc_facility_mappings.empty?
      Rails.logger.info "#{facility.name} has not CPHC facility mappings"
      throw "#{facility.name} not mapped to any CPHC facilities"
    end

    if CphcFacilityMapping.with_user(facility).present?
      Rails.logger.info "#{facility.name} already has an user"
      throw "CPHC user for #{facility.name} aleady exists"
    end

    response = OneOff::CphcEnrollment::CreateUserRequest.call(facility)
    facility.cphc_facility_mappings.update_all(
      cphc_user_details: {
        user_id: response.first["createdUserId"]
      }
    )
  end
end
