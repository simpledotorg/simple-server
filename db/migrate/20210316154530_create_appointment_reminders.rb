class CreateAppointmentReminders < ActiveRecord::Migration[5.2]
  def change
    create_table :appointment_reminders do |t|
      t.uuid :id, primary_key: true
      t.date :remind_on, null: false
      t.string :status, null: false
      t.references :patient
      t.references :experiment
      t.references :appointment
      t.timestamps
    end
  end
end
