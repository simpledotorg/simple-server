class CreateReminderTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :reminder_templates, id: :uuid do |t|
      t.string :message, null: false
      t.integer :appointment_offset, null: false
      t.references :treatment_bucket, type: :uuid, null: false, foreign_key: true
      t.timestamps null: false
    end
  end
end
