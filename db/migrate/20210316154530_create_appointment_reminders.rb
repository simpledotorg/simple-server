class CreateAppointmentReminders < ActiveRecord::Migration[5.2]
  def change
    create_table :appointment_reminders, id: :uuid do |t|
      t.date :remind_on, null: false
      t.string :status, null: false
      t.references :experiment
      t.references :appointment, type: :uuid, null: false, foreign_key: true
      t.datetime :deleted_at, null: true
      t.timestamps
    end
  end
end
