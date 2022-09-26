require "http"

class OneOff::CPHCEnrollment::Request
  attr_reader :path, :user, :payload

  def initialize(path:, user:, payload:)
    @path = path
    @user = user
    @payload = payload
  end

  def post
    HTTP.headers(headers)
      .auth(user[:user_authorization])
      .post(path, json: payload.payload)
  end

  def headers
    {txnUser: user[:user_id],
     facilityTypeId: user[:facility_type_id],
     statecode: user[:state_code],
     isCdssFacility: false}
  end
end
