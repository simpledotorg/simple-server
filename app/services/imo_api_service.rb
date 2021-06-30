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

  attr_reader :patient, :response
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
    @response = execute_post(url, body: request_body)
    result = process_response(@response, url, "invitation")
    ImoAuthorization.create!(patient: patient, status: result, last_invited_at: Time.current)
  end

  def send_notification(message)
    # guard against no imo auth
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
    @response = execute_post(url, body: request_body)
    result = process_response(@response, url, "notification")
    unless result == :success
      patient.imo_authorization.update!(status: result)
    end
  end

  private

  def execute_post(url, data)
    HTTP
      .basic_auth(user: IMO_USERNAME, pass: IMO_PASSWORD)
      .post(url, data)
  rescue HTTP::Error => e
    raise Error.new("Error while calling the IMO API", path: url, exception_message: e)
  end

  def process_response(res, url, action)
    case res.status
    when 200
      body = JSON.parse(res.body)
      body_status = body.dig("response", "status")
      return :invited if body_status == "success" && action == "invitation"
      return :success if body_status == "success" && action == "notification"

      case body.dig("response", "error_code")
      when "not_subscribed"
        Statsd.instance.increment("imo.#{action}.not_subscribed")
        :not_subscribed
      when "invalid_url"
        raise Error.new("Invalid Imo action url", path: url, response: res)
      else
        Statsd.instance.increment("imo.#{action}.error")
        raise Error.new("Unknown 200 error from Imo", path: url, response: res)
      end
    when 400
      if JSON.parse(res.body).dig("response", "type") == "nonexistent_user"
        Statsd.instance.increment("imo.#{action}.no_imo_account")
        :no_imo_account
      else
        Statsd.instance.increment("imo.#{action}.error")
        raise Error.new("Unknown 400 error from IMO", path: url, response: res)
      end
    else
      Statsd.instance.increment("imo.#{action}.error")
      raise Error.new("Unknown response error from IMO", path: url, response: res)
    end
  end

  def invitation_message
    "This will need to be a localized string"
  end
end
