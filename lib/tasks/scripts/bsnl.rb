class Bsnl
  attr_reader :service_id, :username, :password, :token_id

  def initialize(service_id, username, password, token_id)
    @service_id = service_id
    @username = username
    @password = password
    @token_id = token_id
  end

  def refresh_sms_jwt
    abort "Aborting, need BSNL credentials to refresh JWT." unless service_id && username && password && token_id

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
      config = Configuration.find_or_create_by(name: "bsnl_sms_jwt")
      config.update!(value: jwt)
    end
  end
end
