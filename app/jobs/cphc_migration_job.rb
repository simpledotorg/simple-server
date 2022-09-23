class CPHCMigrationJob < ApplicationJob
  queue_as :cphc_migration

  def perform(patient_id, user_id)
    OneOff::CPHCEnrollment::Service.new(
      Patient.find(patient_id),
      User.find(user_id)
    ).call
  end
end
