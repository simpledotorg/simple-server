# Builds the request Simple sends to the voice agent for one overdue appointment.
# Only what the agent must say or dial leaves Simple; patient and appointment IDs never do.
class VoiceAgent::CallRequest
  CALL_REQUEST_ID_NAMESPACE = "9b0c7f4e-2a51-4f8e-9d3c-6a1e8b7d5c20"
  DEFAULT_CALLING_WINDOW_START = "10:00"
  DEFAULT_CALLING_WINDOW_END = "17:00"
  DEFAULT_MAX_TRIES = 3
  STOCK_REPORT_LOOKBACK_MONTHS = 2

  def initialize(notification)
    @notification = notification
  end

  # Derived from the notification so a retried job sends the same ID and the
  # voice agent can drop the duplicate instead of calling the patient twice.
  def call_request_id
    Digest::UUID.uuid_v5(CALL_REQUEST_ID_NAMESPACE, notification.id)
  end

  def payload
    {
      call_request_id: call_request_id,
      country: CountryConfig.current[:abbreviation],
      phone_number: phone_number,
      language: facility.locale,
      patient_name: patient.full_name,
      facility_name: facility.short_name,
      appointment_date: appointment.scheduled_date.iso8601,
      bp_control_status: bp_control_status,
      medicines_in_stock: medicines_in_stock,
      calling_window: calling_window,
      tries: ENV.fetch("VOICE_AGENT_MAX_TRIES", DEFAULT_MAX_TRIES).to_i,
      callback_url: callback_url
    }.compact
  end

  private

  attr_reader :notification

  def appointment
    notification.subject || raise(Messaging::MissingReferenceError.new("Appointment missing/deleted"))
  end

  def patient
    notification.patient || raise(Messaging::MissingReferenceError.new("Patient missing/deleted"))
  end

  def facility
    appointment.facility || raise(Messaging::MissingReferenceError.new("Facility missing/deleted"))
  end

  def phone_number
    patient.latest_mobile_number || raise(Messaging::MissingReferenceError.new("Patient has no mobile number"))
  end

  # Omitted when the patient has no BP, so the agent does not talk about control it can't know.
  def bp_control_status
    blood_pressure = patient.latest_blood_pressure
    return unless blood_pressure

    blood_pressure.under_control? ? "controlled" : "uncontrolled"
  end

  # True only when every drug in the facility's latest stock report is in stock, so the agent
  # never promises medicines that may not be there. Omitted when there is no recent report;
  # the voice agent then treats stock as unavailable.
  def medicines_in_stock
    drug_stocks = latest_drug_stocks.reject { |drug_stock| drug_stock.in_stock.nil? }
    return if drug_stocks.empty?

    drug_stocks.all? { |drug_stock| drug_stock.in_stock.positive? }
  end

  def latest_drug_stocks
    STOCK_REPORT_LOOKBACK_MONTHS.times do |months_ago|
      end_of_month = months_ago.months.ago.end_of_month.to_date
      drug_stocks = DrugStock.latest_for_facilities([facility], end_of_month).to_a
      return drug_stocks if drug_stocks.any?
    end

    []
  end

  def calling_window
    {
      start: ENV.fetch("VOICE_AGENT_CALLING_WINDOW_START", DEFAULT_CALLING_WINDOW_START),
      end: ENV.fetch("VOICE_AGENT_CALLING_WINDOW_END", DEFAULT_CALLING_WINDOW_END),
      tz: CountryConfig.current[:time_zone]
    }
  end

  def callback_url
    "#{ENV["SIMPLE_SERVER_HOST_PROTOCOL"]}://#{ENV["SIMPLE_SERVER_HOST"]}/api/v4/voice_call_outcomes"
  end
end
