class ImoApiService
  IMO_USERNAME = "add_username_to_env"
  IMO_PASSWORD = "add_password_to_env"
  BASE_URL = "https://sgp.imo.im/api/simple/"

  class ImoApiService::HTTPError < HTTP::Error
  end

  attr_reader :phone_number, :message, :recipient_name

  def initialize(phone_number:, message:, recipient_name:)
    @phone_number = phone_number
    @message = message
    @recipient_name = recipient_name
  end

  def invite
    url = BASE_URL + "invite"
    request_body = {
      phone: phone_number,
      msg: message,
      contents:  [{"key": "Name", "value": recipient_name}, {"key": "Notes", "value": message}],
      title: "Invitation",
      action: "Click here"
    }
    execute_post(url, form: request_body)
  end

  private

  def execute_post(url, data)
    response = HTTP
                .basic_auth(user: IMO_USERNAME, pass: IMO_PASSWORD)
                .post(url, data)
    puts response
  rescue HTTP::Error => e
    # report_error(url, e)
    raise ImoApiService::HTTPError
  end
end
