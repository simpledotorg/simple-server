class Imo::InvitePatient < ApplicationJob
  queue_as :default

  attr_reader :patient

  def perform(patient_id)
    @patient = Patient.find(patient_id)
    result = client.invite
    return if result == "failure"
    ImoAuthorization.create!(
      patient: patient,
      status: result,
      last_invited_at: Time.current
    )
  end

  private

  def client
    ImoApiService.new(
      phone_number: patient.latest_mobile_number,
      recipient_name: patient.full_name,
      locale: patient.locale
    )
  end
end