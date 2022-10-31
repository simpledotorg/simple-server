require "http"

class OneOff::CphcEnrollment::Request
  attr_reader :path, :user, :payload

  def initialize(path:, user:, payload:)
    @path = path
    @user = user
    @payload = payload
  end

  def post
    HTTP.headers(headers)
      .post(path, json: payload&.payload || nil)
  end

  def headers
    {txnUser: user[:user_id],
     facilityTypeId: user[:facility_type_id],
     statecode: user[:state_code],
     isCdssFacility: false}.merge(payload&.headers || {})
  end
end
