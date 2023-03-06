class SetupOneOffMedicationRemindersBangladesh < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 8000

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    excluded_facilities = %w[2e7a4917-be56-4d2e-aee6-4c9738ab8a9b edaf3ebd-3dbd-48c3-9911-875ad1356f5d daff41a3-4922-41b0-a822-6fef2db07e68 cc98c651-ce8b-4019-be6b-012f52d0cb21]
    patients = PatientSummary.where(id: Patient
                                          .with_hypertension
                                          .contactable
                                          .where_current_age(">=", 18))
      .where("days_overdue < ?", 365)
      .where.not(assigned_facility_id: excluded_facilities)

    patients.find_in_batches(batch_size: PATIENTS_PER_DAY).with_index do |batch, batch_number|
      batch.each do |patient|
        Notification.create!(
          patient_id: patient.id,
          remind_on: Date.current + batch_number.days + 1,
          status: "scheduled",
          message: "notifications.one_off_medication_reminder",
          purpose: "one_off_medication_reminder"
        )
      end
    end
  end

  def down
    Notification
      .where(purpose: :one_off_medication_reminder)
      .status_scheduled
      .discard_all
  end
end
