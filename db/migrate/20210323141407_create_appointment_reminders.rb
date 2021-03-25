class CreateAppointmentReminders < ActiveRecord::Migration[5.2]
  def change
    create_table :appointment_reminders, id: :uuid do |t|
      t.date :remind_on, null: false
      t.string :status, null: false
      t.string :message, null: false
      t.references :reminder_template, type: :uuid, null: true, foreign_key: true
      t.references :patient, type: :uuid, null: false, foreign_key: true
      t.references :appointment, type: :uuid, null: false, foreign_key: true
      t.timestamps null: false
    end
  end
end
