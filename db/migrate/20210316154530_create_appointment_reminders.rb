class CreateAppointmentReminders < ActiveRecord::Migration[5.2]
  def change
    create_table :appointment_reminders, id: :uuid do |t|
      t.datetime :remind_at, null: false
      t.string :status, null: false
      t.references :patient
      t.references :experiment
      t.references :appointment
      t.datetime :deleted_at, null: true
      t.timestamps
    end
  end
end
