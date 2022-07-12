class Messaging::Bsnl::Api
  HOST = "bulksms.bsnl.in"
  PORT = 5010
  URL_PATHS = {
    get_content_template_details: "/api/Get_Content_Template_Details",
    send_sms: "/api/Send_Sms",
    name_content_template_variables: "/api/Name_Content_Template_Variables",
    message_status_report: "/api/Message_Status_Report",
    get_account_balance: "/api/Get_SMS_Count"
  }

  def initialize
    unless credentials.values.all?
      raise Messaging::Bsnl::CredentialsError.new("Missing BSNL credentials")
    end
  end

  def send_sms(recipient_number:, dlt_template:, key_values:)
    post(URL_PATHS[:send_sms], {
      Header: credentials[:header],
      Target: Phonelib.parse(recipient_number, Rails.application.config.country[:abbreviation]).raw_national,
      Is_Unicode: dlt_template.is_unicode,
      Is_Flash: "0",
      Message_Type: credentials[:message_type],
      Entity_Id: credentials[:entity_id],
      Content_Template_Id: dlt_template.id,
      Template_Keys_and_Values: key_values
    })
  end

  def get_template_details
    post(URL_PATHS[:get_content_template_details])["Content_Template_Ids"]
  end

  def name_template_variables(template_id, template_message_named)
    post(URL_PATHS[:name_content_template_variables], {
      Template_ID: template_id,
      Entity_ID: credentials[:entity_id],
      Template_Message_Named: template_message_named
    })
  end

  def get_message_status_report(message_id)
    post(URL_PATHS[:message_status_report], {
      "Message_id" => message_id
    })
  end

  def get_account_balance
    post(URL_PATHS[:get_account_balance])["Recharge_Details"]
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
