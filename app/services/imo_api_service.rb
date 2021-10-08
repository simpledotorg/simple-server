# API Documentation: https://docs.google.com/document/d/1zaTouxdfGg4IqrkCk59KAP905vwynON5Up2ckUax8Mg/edit

class ImoApiService
  include Rails.application.routes.url_helpers

  IMO_USERNAME = ENV["IMO_USERNAME"]
  IMO_PASSWORD = ENV["IMO_PASSWORD"]
  IMO_BASE_URL = "https://sgp.imo.im/api/simple/".freeze
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

  def send_invitation(patient, phone_number: nil)
    return unless Flipper.enabled?(:imo_messaging)

    Statsd.instance.increment("imo.invites.attempt")

    phone = phone_number || patient.latest_mobile_number
    locale = patient.locale
    url = IMO_BASE_URL + "send_invite"

    unless locale.in?(["bn-BD", "en"])
      raise Error.new("Translation missing for language #{locale}", path: url, patient_id: patient.id)
    end

    request_body = JSON(
      phone: phone,
      msg: I18n.t("notifications.imo.invitation.request", patient_name: patient.full_name, locale: locale),
      contents: [
        {
          key: I18n.t("notifications.imo.section_headers.name", locale: locale),
          value: patient.full_name
        },
        {
          key: I18n.t("notifications.imo.section_headers.message", locale: locale),
          value: I18n.t("notifications.imo.invitation.request", patient_name: patient.full_name, locale: locale)
        }
      ],
      title: I18n.t("notifications.imo.invitation.title", locale: locale),
      action: I18n.t("notifications.imo.invitation.action", locale: locale),
      callback_url: invitation_callback_url(patient.id)
    )

    response = execute_post(url, body: request_body)
    response_body = JSON.parse(response.body)
    process_response(response.status, response_body, request_body, "invitation")
  end

  def send_notification(notification, phone_number)
    return unless Flipper.enabled?(:imo_messaging)

    Statsd.instance.increment("imo.notifications.attempt")

    patient = notification.patient
    locale = patient.locale
    message = notification.localized_message
    url = IMO_BASE_URL + "send_notification"

    unless locale.in?(["bn-BD", "en"])
      raise Error.new("Translation missing for language #{locale}", path: url, patient_id: patient.id)
    end

    request_body = JSON(
      phone: phone_number,
      msg: message,
      contents: [
        {
          key: I18n.t("notifications.imo.section_headers.name", locale: locale),
          value: patient.full_name
        },
        {
          key: I18n.t("notifications.imo.section_headers.message", locale: locale),
          value: message
        }
      ],
      title: I18n.t("notifications.imo.appointment_reminder.title", locale: locale),
      action: I18n.t("notifications.imo.appointment_reminder.action", locale: locale),
      url: PATIENT_REDIRECT_URL,
      callback_url: notification_callback_url
    )

    response = execute_post(url, body: request_body)
    response_body = JSON.parse(response.body)
    result = process_response(response.status, response_body, request_body, "notification")
    post_id = body.dig("response", "result", "post_id")
    {result: result, post_id: post_id}
  end

  private

  def execute_post(url, data)
    HTTP
      .basic_auth(user: IMO_USERNAME, pass: IMO_PASSWORD)
      .post(url, data)
  rescue HTTP::Error => e
    raise Error.new("Error while calling the Imo API", path: url, exception_message: e)
  end

  def process_response(response_status, response_body, request_body, action)
    case response_status
    when 200
      if body.dig("response", "status") == "success"
        return :invited if action == "invitation"
        return :sent if action == "notification"
      end

      case body.dig("response", "error_code")
      when "not_subscribed"
        Statsd.instance.increment("imo.#{action}.not_subscribed")
        return :not_subscribed
      when "subscribed"
        Statsd.instance.increment("imo.#{action}.already_subscribed")
        return :subscribed
      when "invited"
        Statsd.instance.increment("imo.#{action}.already_invited")
        return :invited
      end
    when 400
      if body.dig("response", "type") == "nonexistent_user"
        Statsd.instance.increment("imo.#{action}.no_imo_account")
        return :no_imo_account
      end
    end
    raise Error.new("Error while calling the Imo API", path: url, response: response)
  end

  def invitation_callback_url(patient_id)
    api_v3_imo_authorization_callback_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL"),
      patient_id: patient_id
    )
  end

  def notification_callback_url
    api_v3_imo_notification_callback_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
  end
end
