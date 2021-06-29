class ImoApiService
  IMO_USERNAME = ENV["IMO_USERNAME"]
  IMO_PASSWORD = ENV["IMO_PASSWORD"]
  BASE_URL = "https://sgp.imo.im/api/simple/".freeze
  USER_FACING_URL = "https://www.nhf.org.bd/".freeze

  class Error < StandardError
    attr_reader :path, :response, :exception_message
    def initialize(message, path: nil, response: nil, exception_message: nil)
      super(message)
      @path = path
      @response = response
      @exception_message = exception_message
    end
  end

  attr_reader :patient

  def initialize(patient)
    @patient = patient
  end

  def invite
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
    result = process_invitation_response(response, url)
    ImoAuthorization.create!(patient: patient, status: result, last_invited_at: Time.current)
  end

  def send_notification(message)
    return unless Flipper.enabled?(:imo_messaging)

    Statsd.instance.increment("imo.notifications.attempt")
    url = BASE_URL + "send_notification"
    request_body = JSON(
      phone: patient.latest_mobile_number,
      msg: message,
      contents: [{key: "Name", value: patient.full_name}, {key: "Notes", value: message}],
      title: "Notification",
      action: "Click here",
      url: USER_FACING_URL,
      read_receipt: "will be filled in later"
    )
    response = execute_post(url, body: request_body)
    process_notification_response(response, url)
  end

  private

  def execute_post(url, data)
    HTTP
      .basic_auth(user: IMO_USERNAME, pass: IMO_PASSWORD)
      .post(url, data)
  rescue HTTP::Error => e
    raise Error.new("Error while calling the IMO API", path: url, exception_message: e)
  end

  def process_invitation_response(response, url)
    case response.status
    when 200 then :invited
    when 400
      if JSON.parse(response.body).dig("response", "type") == "nonexistent_user"
        Statsd.instance.increment("imo.invites.no_imo_account")
        :no_imo_account
      else
        Statsd.instance.increment("imo.invites.error")
        raise Error.new("Unknown 400 error from IMO", path: url, response: response)
      end
    else
      Statsd.instance.increment("imo.invites.error")
      raise Error.new("Unknown response error from IMO", path: url, response: response)
    end
  end

  def process_notification_response(response, url)
    case response.status
    when 200
      error_code = JSON.parse(response.body).dig("response", "error_code")
      case error_code
      when "not_subscribed"
        :unsubscribed
        Statsd.instance.increment("imo.invites.no_imo_account")
      when "invalid_url"
        raise Error.new("Imo action url invalid", path: url, response: response)
      else
        :success
      end
    when 400
      if JSON.parse(response.body).dig("response", "type") == "nonexistent_user"
        Statsd.instance.increment("imo.invites.no_imo_account")
        :no_imo_account
      else
        Statsd.instance.increment("imo.invites.error")
        raise Error.new("Unknown 400 error from IMO", path: url, response: response)
      end
    else
      Statsd.instance.increment("imo.invites.error")
      raise Error.new("Unknown response error from IMO", path: url, response: response)
    end
  end

  def invitation_message
    "This will need to be a localized string"
  end
end
