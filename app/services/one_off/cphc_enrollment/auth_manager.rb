class OneOff::CphcEnrollment::AuthManager
  attr_reader :facility

  def initialize(facility)
    @facility = facility
  end

  def user
    facility.cphc_facility.cphc_user_details.with_indifferent_access
  end

  def create_user
    cphc_facility = facility.cphc_facility

    unless cphc_facility.present?
      Rails.logger.info "#{facility.name} has not CPHC facility mappings"
      throw "#{facility.name} not mapped to any CPHC facilities"
    end

    if cphc_facility.cphc_user_details.present?
      Rails.logger.info "#{facility.name} already has an user"
      throw "CPHC user for #{facility.name} aleady exists"
    end

    response = if cphc_facility.cphc_facility_type == "SUBCENTER"
      OneOff::CphcEnrollment::CreateSubcenterUserRequest.call(facility)
    elsif cphc_facility.cphc_facility_type == "PHC"
      OneOff::CphcEnrollment::CreateUserRequest.call(facility)
    end

    cphc_facility.update!(
      cphc_user_details: {
        user_id: response.first["createdUserId"],
        facility_type_id: cphc_facility.cphc_facility_type_id,
        state_code: cphc_facility.cphc_state_id
      }
    )
  end
end
