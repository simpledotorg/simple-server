class CphcMigrationJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :cphc_migration, retry: SimpleServer.env.development?
  sidekiq_throttle(
    threshold: {limit: 10, period: 10.seconds}
  )

  def perform(patient_id, user_json)
    patient = Patient.find(patient_id)
    user = JSON.parse(user_json)
    OneOff::CphcEnrollment::Service.new(patient, user.with_indifferent_access).call
  end
end
