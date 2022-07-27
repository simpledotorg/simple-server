require "http"
class CPHCEnrollment::Request

  attr_reader :path, :user, :payload

  def initialize(path:, user:, payload:)
    @path = path
    @user = user
    @payload = payload
  end

  def post
    puts "Payload: #{payload.as_json}"
    HTTP.headers(headers)
        .auth(user[:user_authorization])
        .post(path, json: payload.as_json)
  end

  def headers
    {txnUser: user[:user_id],
     facilityTypeId: user[:facility_type_id],
     statecode: user[:state_code]}
  end
end
