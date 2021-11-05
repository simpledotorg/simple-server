class Communication < ApplicationRecord
  include Mergeable
  include Hashable

  belongs_to :appointment, optional: true
  belongs_to :notification, optional: true
  belongs_to :user, optional: true
  belongs_to :detailable, polymorphic: true, optional: true

  delegate :unsuccessful?, :successful?, :in_progress?, to: :detailable

  # the missed_visit types are being deprecated
  # keeping here to avoid invalidating records until we change existing records as part of:
  # https://app.clubhouse.io/simpledotorg/story/3585/backfill-notifications-from-communications
  enum communication_type: {
    voip_call: "voip_call",
    manual_call: "manual_call",
    sms: "sms",
    whatsapp: "whatsapp",
    missed_visit_sms_reminder: "missed_visit_sms_reminder",
    missed_visit_whatsapp_reminder: "missed_visit_whatsapp_reminder",
    imo: "imo"
  }

  COMMUNICATION_RESULTS = {
    unavailable: "unavailable",
    unreachable: "unreachable",
    successful: "successful",
    unsuccessful: "unsuccessful",
    in_progress: "in_progress",
    unknown: "unknown"
  }

  ANONYMIZED_DATA_FIELDS = %w[id appointment_id patient_id user_id created_at communication_type
    communication_result]

  DEFAULT_MESSAGING_START_HOUR = 14
  DEFAULT_MESSAGING_END_HOUR = 16

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  scope :with_delivery_detail, -> {
    joins("inner join twilio_sms_delivery_details delivery_detail on delivery_detail.id = communications.detailable_id")
  }

  def self.latest_by_type(communication_type)
    send(communication_type).order(device_created_at: :desc).first
  end

  def self.create_with_twilio_details!(appointment:, twilio_sid:, twilio_msg_status:, communication_type:, notification: nil)
    patient = notification.patient
    now = DateTime.current
    transaction do
      sms_delivery_details = TwilioSmsDeliveryDetail.create!(session_id: twilio_sid,
                                                             result: twilio_msg_status,
                                                             callee_phone_number: patient.latest_mobile_number)
      communication = create!(communication_type: communication_type,
                              detailable: sms_delivery_details,
                              appointment: appointment,
                              notification: notification,
                              device_created_at: now,
                              device_updated_at: now)
      logger.info(class: self.class.name, msg: __method__.to_s, communication_id: communication.id,
                  communication_type: communication_type, appointment_id: appointment&.id, result: twilio_msg_status,
                  notification_id: notification&.id)
    end
  end

  def self.create_with_imo_details!(notification:, result:, post_id:)
    patient = notification.patient
    now = DateTime.current
    transaction do
      detailable = ImoDeliveryDetail.create!(callee_phone_number: patient.latest_mobile_number, result: result, post_id: post_id)
      communication = create!(communication_type: :imo,
                              detailable: detailable,
                              appointment: notification.subject,
                              notification: notification,
                              device_created_at: now,
                              device_updated_at: now)

      if detailable.unsubscribed_or_missing?
        patient = notification.patient
        patient.imo_authorization.update!(status: detailable.result)
      end

      logger.info(class: self.class.name, msg: __method__.to_s, communication_id: communication.id,
                  communication_type: "imo", appointment_id: notification.subject&.id, notification_id: notification&.id)
    end
  end

  def self.messaging_start_hour
    @messaging_start_hour ||= ENV.fetch("APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_START", DEFAULT_MESSAGING_START_HOUR).to_i
  end

  def self.messaging_end_hour
    @messaging_end_hour ||= ENV.fetch("APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_FINISH", DEFAULT_MESSAGING_END_HOUR).to_i
  end

  def self.next_messaging_time
    now = DateTime.now.in_time_zone(Rails.application.config.country[:time_zone])
    return now if Flipper.enabled?(:disregard_messaging_window)

    if now.hour < messaging_start_hour
      now.change(hour: messaging_start_hour)
    elsif now.hour >= messaging_end_hour
      now.change(hour: messaging_start_hour).advance(days: 1)
    else
      now
    end
  end

  def communication_result
    if successful?
      COMMUNICATION_RESULTS[:successful]
    elsif unsuccessful?
      COMMUNICATION_RESULTS[:unsuccessful]
    elsif in_progress?
      COMMUNICATION_RESULTS[:in_progress]
    else
      COMMUNICATION_RESULTS[:unknown]
    end
  end

  def attempted?
    successful? || in_progress?
  end

  def anonymized_data
    {id: hash_uuid(id),
     user_id: hash_uuid(user_id),
     created_at: created_at,
     communication_type: communication_type,
     communication_result: communication_result}
  end
end
