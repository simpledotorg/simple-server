class Messaging::Bsnl::Api
  HOST = "bulksms.bsnl.in"
  PORT = 5010

  def self.get_template_details
    post("/api/Get_Content_Template_Details")["Content_Template_Ids"]
  end


  def self.credentials
    {
      header: ENV["BSNL_IHCI_HEADER"],
      message_type: "SI",
      entity_id: ENV["BSNL_IHCI_ENTITY_ID"],
      jwt: ENV["BSNL_JWT_TOKEN"]
    }
  end

  def self.post(path, body = nil)
    raise Messaging::Error "Missing BSNL credentials" unless credentials.values.all?

    http = Net::HTTP.new(HOST, PORT)
    http.use_ssl = true
    request = Net::HTTP::Post.new(path, "Content-Type" => "application/json")

    request.body = body.to_json if body
    request["Authorization"] = "Bearer #{credentials[:jwt]}"
    response = http.request(request).body

    begin
      JSON.parse(response)
    rescue JSON::ParserError
      response
    end
  end
end
