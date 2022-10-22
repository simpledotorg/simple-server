class OneOff::CphcEnrollment::AuthManager
  attr_reader :facility

  def initialize(facility)
    @facility = facility
  end

  def user
    CphcFacilityMapping.with_user(facility).cphc_user_details
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
