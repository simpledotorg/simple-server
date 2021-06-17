class ImoApiService
  IMO_USERNAME = "add_username_to_env"
  IMO_PASSWORD = "add_password_to_env"
  BASE_URL = "https://sgp.imo.im/api/simple/"

  class ImoApiService::HTTPError < HTTP::Error
  end

  attr_reader :phone_number, :recipient_name, :locale

  def initialize(phone_number:, recipient_name:, locale:)
    @phone_number = phone_number
    @recipient_name = recipient_name
    @locale = locale
  end

  def invite
    url = BASE_URL + "send_invite"
    request_body = {
      phone: phone_number,
      msg: invitation_message,
      contents: [{key: "Name", value: recipient_name}, {key: "Notes", value: invitation_message}],
      title: "Invitation",
      action: "Click here"
    }.to_json
    response = execute_post(url, body: request_body)
    result = process_response(response)
    if result == "failure"
      report_error(description: "Failed Imo invitation", api_path: url, response: response)
    end
    result
  end

  private

  def execute_post(url, data)
    HTTP
      .basic_auth(user: IMO_USERNAME, pass: IMO_PASSWORD)
      .post(url, data)
  rescue HTTP::Error => e
    report_error(description: "Error while calling the Imo API", api_path: url, exception: e)
    raise ImoApiService::HTTPError
  end

  def process_response(response)
    return "invited" if response.status == 200
    if response.status == 400
      parsed = JSON.parse(response.body)
      error_type = parsed.dig("response", "type")
      return "no_imo_account" if error_type == "nonexistent_user"
    end
    "failure"
  end

  def invitation_message
    "This will need to be a localized string"
  end

  def report_error(description:, api_path:, exception: nil, response: nil)
    Sentry.capture_message(
      description,
      extra: {
        api_path: api_path,
        exception: exception.to_s,
        response_status: response&.status,
        body: response&.body&.to_s
      },
      tags: {type: "imo-api"}
    )
  end
end
