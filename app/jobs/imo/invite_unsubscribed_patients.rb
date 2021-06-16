class Imo::InviteUnsubscribedPatients < ApplicationJob
  queue_as :default

  def perform
    return unless Flipper.enabled?(:imo_messaging)
    patients.each do |patient|
      Imo::InvitePatient.perform_now(patient.id)
    end
  end

  def patients
    Patient
      .contactable
      .left_joins(:imo_authorization)
      .where(imo_authorizations: {id: nil})
  end
end