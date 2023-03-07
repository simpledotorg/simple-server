class SetupOneOffMedicationRemindersBangladesh < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 8000
  EXCLUDED_FACILITIES = %w[
    2e7a4917-be56-4d2e-aee6-4c9738ab8a9b
    edaf3ebd-3dbd-48c3-9911-875ad1356f5d
    daff41a3-4922-41b0-a822-6fef2db07e68
    cc98c651-ce8b-4019-be6b-012f52d0cb21
  ]

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    patients =
      PatientSummary
        .joins(:patient)
        .merge(Patient.contactable)
        .where("current_age >= ?", 18)
        .where("days_overdue < ?", 365)
        .where(next_appointment_status: :scheduled)
        .where("next_appointment_scheduled_date < ?", Date.today)
        .where.not(assigned_facility_id: EXCLUDED_FACILITIES)

    patients.find_in_batches(batch_size: PATIENTS_PER_DAY).with_index do |batch, batch_number|
      batch.each do |patient|
        Notification.create!(
          patient_id: patient.id,
          remind_on: Date.current + batch_number.days + 1,
          status: "pending",
          message: "notifications.one_off_medications_reminder",
          purpose: "one_off_medications_reminder"
        )
      end
    end
  end

  def down
    Notification
      .where(purpose: :one_off_medications_reminder)
      .where(status: [:pending, :scheduled])
      .update_all(status: :cancelled, deleted_at: Time.now)
  end
end
