class Imo::InviteUnsubscribedPatients
  include Sidekiq::Worker

  sidekiq_options queue: :default

  REINVITATION_BUFFER = 6.months.freeze

  def perform(patient_count = 0)
    return unless Flipper.enabled?(:imo_messaging)

    next_messaging_time = Communication.next_messaging_time
    patient_ids(patient_count).each do |patient_id|
      Imo::InvitePatient.perform_at(next_messaging_time, patient_id)
    end
  end

  def patient_ids(patient_count)
    Patient
      .contactable
      .not_ltfu_as_of(Time.current)
      .left_joins(:imo_authorization)
      .where(
        "(imo_authorizations.last_invited_at < ? AND imo_authorizations.status != ?) OR imo_authorizations.id IS NULL",
        REINVITATION_BUFFER.ago, "subscribed"
      )
      .limit(patient_count)
      .pluck(:id)
  end
end
