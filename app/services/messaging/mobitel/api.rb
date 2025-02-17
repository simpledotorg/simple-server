class Messaging::Mobitel::Api
  HOST = "https://msmsenterpriseapi.mobitel.lk"
  SEND_SMS_PATH = "/EnterpriseSMSV3/esmsproxyMultilang.php"
  MESSAGE_TYPE = {
    non_promotional: 0,
    promotional: 1
  }

  def initialize
    raise Messaging::Mobitel::Error.new("Missing Mobitel SMS Alias") if message_alias.blank?
    raise Messaging::Mobitel::Error.new("Missing Mobitel username") if api_username.blank?
    raise Messaging::Mobitel::Error.new("Missing Mobitel password") if api_password.blank?
  end

  def send_sms(recipient_number:, message:)
    post(SEND_SMS_PATH, {
      message: message,
      recipient: recipient_number,
      alias: message_alias,
      username: api_username,
      password: api_password,
      messageType: message_type
    })
  end

  private

  def message_type
    MESSAGE_TYPE[:non_promotional]
  end

  def message_alias
    ENV["MOBITEL_SMS_ALIAS"]
  end

  def api_username
    ENV["MOBITEL_API_USERNAME"]
  end

  def api_password
    ENV["MOBITEL_API_PASSWORD"]
  end

  def post(path, body = {})
    uri = URI("#{HOST}#{path}")
    response = Net::HTTP.post(uri, body.to_json)

    unless response.is_a?(Net::HTTPSuccess)
      raise Messaging::Mobitel::Error.new(
        "Mobitel API returned #{response.code} with #{response.body}"
      )
    end
    is_success(response)
  end

  def is_success(response)
    JSON.parse(response.body)
  rescue JSON::ParserError
    raise Messaging::Mobitel::Error.new(
      "Non standard response received for Mobitel API: #{response.body}"
    )
  end
end
