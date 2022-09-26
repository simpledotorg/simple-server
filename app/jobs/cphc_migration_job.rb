class CPHCMigrationJob < ApplicationJob
  queue_as :cphc_migration
  sidekiq_options retry: false

  def perform(patient, user)
    OneOff::CPHCEnrollment::Service.new(patient, user).call
  end
end
