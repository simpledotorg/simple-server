class Messaging::Bsnl::Api
  HOST = "bulksms.bsnl.in"
  PORT = 5010
  URL_PATHS = {
    get_content_template_details: "/api/Get_Content_Template_Details",
    send_sms: "/api/Send_Sms"
  }

  def initialize
    unless credentials.values.all?
      raise Messaging::Bsnl::Error.new("Missing BSNL credentials")
    end
  end

  def send_sms(recipient_number:, dlt_template_id:, key_values:)
    post(URL_PATHS[:send_sms], {
      Header: credentials[:header],
      Target: Phonelib.parse(recipient_number, Rails.application.config.country[:abbreviation]).raw_national,
      Is_Unicode: "0",
      Is_Flash: "0",
      Message_Type: credentials[:message_type],
      Entity_Id: credentials[:entity_id],
      Content_Template_Id: dlt_template_id,
      Template_Keys_and_Values: key_values
    })
  end

  def get_template_details
    post(URL_PATHS[:get_content_template_details])["Content_Template_Ids"]
  end

  private

  def credentials
    {
      header: ENV["BSNL_IHCI_HEADER"],
      message_type: "SI",
      entity_id: ENV["BSNL_IHCI_ENTITY_ID"],
      jwt: Configuration.fetch("bsnl_sms_jwt") || ENV["BSNL_JWT_TOKEN"]
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
