# API Documentation: https://docs.google.com/document/d/1zaTouxdfGg4IqrkCk59KAP905vwynON5Up2ckUax8Mg/edit

class ImoApiService
  IMO_USERNAME = ENV["IMO_USERNAME"]
  IMO_PASSWORD = ENV["IMO_PASSWORD"]
  BASE_URL = "https://sgp.imo.im/api/simple/".freeze
  # this is where the patient is redirected to when they click on the invitation card details section
  PATIENT_REDIRECT_URL = "https://www.nhf.org.bd".freeze

  class Error < StandardError
    attr_reader :path, :response, :exception_message, :patient_id
    def initialize(message, path: nil, response: nil, exception_message: nil, patient_id: nil)
      super(message)
      @path = path
      @response = response
      @exception_message = exception_message
      @patient_id = patient_id
    end
  end

  def send_invitation(patient)
    return unless Flipper.enabled?(:imo_messaging)

    locale = patient.locale
    Statsd.instance.increment("imo.invites.attempt")
    url = BASE_URL + "send_invite"
    request_body = JSON(
      phone: patient.latest_mobile_number,
      msg: I18n.t("notifications.imo.invitations.message", locale: locale),
      contents: [{
        key: I18n.t("notifications.imo.invitations.message_key", locale: locale),
        value: I18n.t("notifications.imo.invitations.message", locale: locale)
      }],
      title: I18n.t("notifications.imo.invitations.title", locale: locale),
      action: I18n.t("notifications.imo.invitations.action", locale: locale)
    )

    if request_body.include?("translation missing")
      raise Error.new("Translation missing for language #{locale}", path: url, patient_id: patient.id)
    end

    response = execute_post(url, body: request_body)
    result = process_response(response, url, "invitation")

    return if result.nil?

    ImoAuthorization.create!(patient: patient, status: result, last_invited_at: Time.current)
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

    return if result.nil?

    unless patient.imo_authorization.status == result.to_s
      patient.imo_authorization.update!(status: result)
    end
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
      body_status = body.dig("response", "status")
      return :invited if body_status == "success" && action == "invitation"
      # until we implement the invitation callback, the only way for us to know if the user
      # has accepted our invitation is to send a notication to see if it succeeds
      return :subscribed if body_status == "success" && action == "notification"

      case body.dig("response", "error_code")
      when "not_subscribed"
        Statsd.instance.increment("imo.#{action}.not_subscribed")
        :not_subscribed
      else
        Statsd.instance.increment("imo.#{action}.error")
        report_error("Unknown 200 error from Imo", url, response)
        nil
      end
    when 400
      if JSON.parse(response.body).dig("response", "type") == "nonexistent_user"
        Statsd.instance.increment("imo.#{action}.no_imo_account")
        :no_imo_account
      else
        Statsd.instance.increment("imo.#{action}.error")
        report_error("Unknown 400 error from Imo", url, response)
        nil
      end
    else
      Statsd.instance.increment("imo.#{action}.error")
      report_error("Unknown 400 error from Imo", url, response)
      nil
    end
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
