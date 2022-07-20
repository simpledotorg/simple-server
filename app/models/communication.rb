class Communication < ApplicationRecord
  include Mergeable
  include Hashable

  belongs_to :notification, optional: true
  belongs_to :detailable, polymorphic: true, optional: true

  delegate :unsuccessful?, :successful?, :in_progress?, to: :detailable

  # the missed_visit types are being deprecated
  # keeping here to avoid invalidating records until we change existing records as part of:
  # https://app.clubhouse.io/simpledotorg/story/3585/backfill-notifications-from-communications
  enum communication_type: {
    voip_call: "voip_call",
    manual_call: "manual_call",
    sms: "sms",
    whatsapp: "whatsapp"
  }

  COMMUNICATION_RESULTS = {
    unavailable: "unavailable",
    unreachable: "unreachable",
    successful: "successful",
    unsuccessful: "unsuccessful",
    in_progress: "in_progress",
    unknown: "unknown"
  }

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at communication_type communication_result]
  DEFAULT_MESSAGING_START_HOUR = 14
  DEFAULT_MESSAGING_END_HOUR = 16

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
     created_at: created_at,
     communication_type: communication_type,
     communication_result: communication_result}
  end
end
