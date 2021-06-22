class Imo::InvitePatient
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(patient_id)
    return unless Flipper.enabled?(:imo_messaging)

    patient = Patient.find(patient_id)
    result = ImoApiService.new(patient).invite
    ImoAuthorization.create!(patient: patient, status: result, last_invited_at: Time.current)
  end
end
