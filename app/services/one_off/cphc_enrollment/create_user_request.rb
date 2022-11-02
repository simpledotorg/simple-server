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
    "#{ENV["CPHC_BASE_URL"]}/adminOperations/locationType/PHC/locationId/#{location_id}/createUser"
  end

  def headers
    {"stateCode" => state_code, "txnUser" => CPHC_TXN_USER, "Host" => CPHC_HOST}
  end

  def payload
    [
      {
        username: username,
        mobileNumber: mobile_number,
        locationId: location_id,
        userType: CPHC_USER_TYPE,
        locationType: cphc_facility_type_id
      }
    ]
  end

  def username
    "deo_ihci_#{cphc_facility_mapping.cphc_phc_id}"
  end

  def mobile_number
    ENV.fetch("CPHC_USER_MOBILE_NUMBER")
  end

  def state_code
    cphc_facility_mapping.cphc_state_id
  end

  def location_id
    cphc_facility_mapping.cphc_phc_id
  end

  def cphc_facility_mapping
    facility.cphc_facility_mappings.first
  end

  def cphc_facility_type_id
    cphc_type = OneOff::CphcEnrollment::FACILITY_TYPE_MAPPING[facility.facility_type]
    OneOff::CphcEnrollment::FACILITY_TYPE_ID[cphc_type]
  end
end
