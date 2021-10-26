class Imo::InvitePatient
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(patient_id)
    return unless Flipper.enabled?(:imo_messaging)

    patient = Patient.find(patient_id)
    status = ImoApiService.new.send_invitation(patient)

    if patient.imo_authorization
      patient.imo_authorization.update!(status: status, last_invited_at: Time.current)
    else
      ImoAuthorization.create!(patient: patient, status: status, last_invited_at: Time.current)
    end
  end
end
