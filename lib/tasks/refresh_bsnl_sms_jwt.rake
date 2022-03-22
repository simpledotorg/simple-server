require "net/http"

namespace :bsnl do
  desc "Fetch a fresh JWT for BSNL Bulk SMS and overwrite the old token"
  task refresh_sms_jwt: :environment do
    service_id = ENV["BSNL_SERVICE_ID"]
    username = ENV["BSNL_USERNAME"]
    password = ENV["BSNL_PASSWORD"]
    token_id = ENV["BSNL_TOKEN_ID"]

    abort unless service_id && username && password && token_id

    http = Net::HTTP.new("bulksms.bsnl.in", 5010)
    http.use_ssl = true
    request = Net::HTTP::Post.new("/api/Create_New_API_Token", "Content-Type" => "application/json")
    request.body = {Service_Id: service_id,
                    Username: username,
                    Password: password,
                    Token_Id: token_id}.to_json
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      jwt = response.body.delete_prefix('"').delete_suffix('"')
      Credential.find("BSNL_SMS_JWT").update(value: jwt)
    else
      #todo: send an alert
    end
  end
end
