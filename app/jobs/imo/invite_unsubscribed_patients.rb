class Imo::InviteUnsubscribedPatients
  include Sidekiq::Worker

  sidekiq_options queue: :default

  REINVITATION_BUFFER = 6.months.freeze

  def perform
    return unless Flipper.enabled?(:imo_messaging)

    next_messaging_time = Communication.next_messaging_time
    patients.each do |patient|
      Imo::InvitePatient.perform_at(next_messaging_time, patient.id)
    end
  end

  def patients
    Patient
      .contactable
      .not_ltfu_as_of(Time.current)
      .left_joins(:imo_authorization)
      .where(
        "imo_authorizations.last_invited_at < ? AND imo_authorizations.status != ? OR imo_authorizations.id IS NULL",
        REINVITATION_BUFFER.ago, "subscribed"
      )
  end
end
