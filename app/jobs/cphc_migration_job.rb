class CPHCMigrationJob
  include Sidekiq::Worker

  sidekiq_options queue: :cphc_migration
  sidekiq_retry_in { |_, _| 24.hours.to_i }

  def perform(patient_id, user_json)
    patient = Patient.find(patient_id)
    user = JSON.parse(user_json)
    OneOff::CPHCEnrollment::Service.new(patient, user.with_indifferent_access).call
  end
end
