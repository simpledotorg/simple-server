class CphcMigrationErrorsDownloadJob
  include Sidekiq::Worker
  sidekiq_options queue: :cphc_migration

  def perform(recipient_email, region_type, slug)
    region = Region.find_by!(region_type: region_type, slug: slug)

    error_patient_ids = region.facilities
      .joins(:cphc_migration_error_logs)
      .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
      .where("cphc_migration_audit_logs.id is null")
      .distinct(:patient_id)
      .pluck(:patient_id)

    patients = Patient.where(id: error_patient_ids)

    exporter = PatientsWithHistoryExporter
    patients_csv = if region.diabetes_management_enabled?
      exporter.csv(patients)
    else
      exporter.csv(patients, display_blood_sugars: 0)
    end

    PatientListDownloadMailer.patient_list(
      recipient_email,
      region.region_type,
      region.name,
      patients_csv
    ).deliver_now
  end
end
