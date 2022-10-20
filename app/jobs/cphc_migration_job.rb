class CphcMigrationJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :cphc_migration, retry: SimpleServer.env.development?
  sidekiq_throttle(
    threshold: {limit: 10, period: 10.seconds}
  )

  def perform(patient_id)
    patient = Patient.find(patient_id)

    if OneOff::CphcEnrollment.in_migration_window?(Time.now)
      user = patient.assigned_facility.cphc_facility_mappings.first.cphc_user
      return OneOff::CphcEnrollment::Service.new(patient, user).call
    end

    next_migration_time = OneOff::CphcEnrollment.next_migration_time(Time.now)
    Rails.logger.info "Job execution exceeds CPHC migration window. Rescheduling for #{next_migration_time}"

    CphcMigrationJob.perform_at(next_migration_time, patient.id)
  end
end
