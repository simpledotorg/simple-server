class ImoApiService
  IMO_USERNAME = ENV["IMO_USERNAME"]
  IMO_PASSWORD = ENV["IMO_PASSWORD"]
  BASE_URL = "https://sgp.imo.im/api/simple/".freeze
  # this is where the patient is redirected to when they click on the invitation card details section
  PATIENT_REDIRECT_URL = "https://www.nhf.org.bd".freeze

  class Error < StandardError
    attr_reader :path, :response, :exception_message
    def initialize(message, path: nil, response: nil, exception_message: nil)
      super(message)
      @path = path
      @response = response
      @exception_message = exception_message
    end
  end

  def send_invitation(patient)
    return unless Flipper.enabled?(:imo_messaging)

    Statsd.instance.increment("imo.invites.attempt")
    url = BASE_URL + "send_invite"
    request_body = JSON(
      phone: patient.latest_mobile_number,
      msg: invitation_message,
      contents: [{key: "Name", value: patient.full_name}, {key: "Notes", value: invitation_message}],
      title: "Invitation",
      action: "Click here"
    )
    response = execute_post(url, body: request_body)
    result = process_response(response, url, "invitation")

    status = result == :success ? :invited : result
    ImoAuthorization.create!(patient: patient, status: status, last_invited_at: Time.current)
  end

  def send_notification(patient, message)
    return unless Flipper.enabled?(:imo_messaging)

    Statsd.instance.increment("imo.notifications.attempt")
    url = BASE_URL + "send_notification"
    request_body = JSON(
      phone: patient.latest_mobile_number,
      msg: message,
      contents: [{key: "Name", value: patient.full_name}, {key: "Notes", value: message}],
      title: "Notification",
      action: "Click here",
      url: PATIENT_REDIRECT_URL,
      read_receipt: "will be filled in later"
    )
    response = execute_post(url, body: request_body)
    result = process_response(response, url, "notification")

    if patient.imo_authorization.status != result.to_s && result.in?([:not_subscribed, :no_imo_account])
      patient.imo_authorization.update!(status: result)
    end
    result
  end

  private

  def execute_post(url, data)
    HTTP
      .basic_auth(user: IMO_USERNAME, pass: IMO_PASSWORD)
      .post(url, data)
  rescue HTTP::Error => e
    raise Error.new("Error while calling the Imo API", path: url, exception_message: e)
  end

  def process_response(response, url, action)
    case response.status
    when 200
      body = JSON.parse(response.body)
      return :success if body.dig("response", "status") == "success"

      if body.dig("response", "error_code") == "not_subscribed"
        Statsd.instance.increment("imo.#{action}.not_subscribed")
        return :not_subscribed
      end
    when 400
      if JSON.parse(response.body).dig("response", "type") == "nonexistent_user"
        Statsd.instance.increment("imo.#{action}.no_imo_account")
        return :no_imo_account
      end
    end
    Statsd.instance.increment("imo.#{action}.error")
    report_error("Unknown #{response.status} error from Imo", url, response)
    :error
  end

  def invitation_message
    "This will need to be a localized string"
  end

  def report_error(message, url, response)
    Sentry.capture_message(
      "Error while calling the Imo API",
      extra: {
        message: message,
        path: url,
        response: response
      },
      tags: {type: "imo-api"}
    )
  end
end
