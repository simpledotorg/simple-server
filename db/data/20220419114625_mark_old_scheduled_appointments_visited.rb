class MarkOldScheduledAppointmentsVisited < ActiveRecord::Migration[5.2]
  def up
    patients_ids_with_multiple_appointments = Patient
      .joins(:latest_scheduled_appointments)
      .group("patients.id")
      .having("count(patients.id) > 1")
      .count
      .keys

    patients_ids_with_multiple_appointments.each do |patient_id|
      old_scheduled_appointments = Patient.find(patient_id).latest_scheduled_appointments.offset(1)
      old_scheduled_appointments.update_all(status: :visited, updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
