class Messaging::Bsnl::Api
  HOST = "bulksms.bsnl.in"
  PORT = 5010

  def initialize
    unless credentials.values.all?
      raise Messaging::Bsnl::Error.new("Missing BSNL credentials")
    end
  end

  def get_template_details
    post("/api/Get_Content_Template_Details")["Content_Template_Ids"]
  end

  private

  def credentials
    {
      header: ENV["BSNL_IHCI_HEADER"],
      message_type: "SI",
      entity_id: ENV["BSNL_IHCI_ENTITY_ID"],
      jwt: Configuration.fetch("bsnl_sms_jwt")
    }
  end

  def post(path, body = nil)
    http = Net::HTTP.new(HOST, PORT)
    http.use_ssl = true
    request = Net::HTTP::Post.new(path, "Content-Type" => "application/json")
    request.body = body.to_json if body
    request["Authorization"] = "Bearer #{credentials[:jwt]}"

    hsh_or_string(http.request(request).body)
  end

  def hsh_or_string(string)
    JSON.parse(string)
  rescue JSON::ParserError
    string.to_s
  end
end
