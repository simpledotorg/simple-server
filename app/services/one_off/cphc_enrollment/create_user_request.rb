class OneOff::CphcEnrollment::CreateUserRequest
  attr_reader :facility

  CPHC_USER_TYPE = "DEO"
  CPHC_TXN_USER = "admin_goi"
  CPHC_HOST = ENV["CPHC_ADMIN_HOST"]

  def initialize(facility)
    @facility = facility
  end

  def self.call(facility)
    new(facility).call
  end

  def call
    response = HTTP.headers(headers)
      .post(path, params: {userType: CPHC_USER_TYPE}, json: payload)

    if response.code != 200
      Rails.logger.error "Request failed", {
        response_code: response.code,
        response_body: response.body.to_s
      }
      CphcMigrationErrorLog.create(
        cphc_migratable: facility,
        facility_id: facility.id,
        failures: {
          response_code: response.code,
          response_body: response.body.to_s
        }
      )
      throw "Request failed with code #{response.status} #{response.body}"
    end

    JSON.parse(response.body.to_s)
  end

  def path
    "#{ENV["CPHC_BASE_URL"]}/adminOperations/locationType/#{location_type}/locationId/#{location_id}/createUser"
  end

  def headers
    {"stateCode" => state_code, "txnUser" => CPHC_TXN_USER, "Host" => CPHC_HOST, "facilityType" => "STATE"}
  end

  def payload
    user = {
      username: username,
      mobileNumber: mobile_number,
      locationId: location_id,
      userType: CPHC_USER_TYPE,
      locationType: location_type
    }

    if ["CHC", "DH"].include? hospital_type
      user[:hospitalId] = hospital_id
      user[:hospitalType] = hospital_type
    end

    [user]
  end

  def username
    return "deo_ihci_phc_#{location_id}" if hospital_type == "PHC"

    "deo_h_#{location_id}_ihci"
  end

  def mobile_number
    ENV.fetch("CPHC_USER_MOBILE_NUMBER")
  end

  def state_code
    cphc_facility.cphc_state_id
  end

  def location_type
    return "PHC" if hospital_type == "PHC"

    "DISTRICT"
  end

  def location_id
    return hospital_id if hospital_type == "PHC"

    cphc_facility.cphc_district_id
  end

  def hospital_type
    cphc_facility.cphc_facility_type
  end

  def hospital_id
    cphc_facility.cphc_facility_id
  end

  def cphc_facility
    facility.cphc_facility
  end
end
