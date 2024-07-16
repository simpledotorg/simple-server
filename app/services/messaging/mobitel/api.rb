class Messaging::Mobitel::Api
  HOST = "https://msmsenterpriseapi.mobitel.lk"
  URL_PATHS = {
    send_sms: "/EnterpriseSMSV3/esmsproxy.php"
  }
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
    post(URL_PATHS[:send_sms], {
      m: message,
      r: recipient_number,
      a: message_alias,
      u: api_username,
      p: api_password,
      t: message_type
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

  def post(path, params = {})
    uri = URI("#{HOST}#{path}")
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    puts uri

    unless response.is_a?(Net::HTTPSuccess)
      raise Messaging::Mobitel::Error.new(
        "Mobitel API returned #{response.code} with #{response.body}"
      )
    end
    is_success(response)
  end

  def is_success(response)
    code = response.body
    unless code.to_i.to_s == code
      raise Messaging::Mobitel::Error.new(
        "Non standard response received for Mobitel API: #{response.body}"
      )
    end
    code.to_i
  end
end
