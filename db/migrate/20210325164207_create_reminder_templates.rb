class CreateReminderTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :reminder_templates, id: :uuid do |t|
      t.string :message, null: false
      t.integer :remind_on_in_days, null: false
      t.references :treatment_group, type: :uuid, null: false, foreign_key: true
      t.timestamps null: false
    end
  end
end
