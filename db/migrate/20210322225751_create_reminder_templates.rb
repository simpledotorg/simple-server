class CreateReminderTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :reminder_templates do |t|
      t.integer :experiment_group, null: false
      t.string :message, null: true
      t.integer :appointment_offset, null: false
      t.references :reminder_experiment, null: false, foreign_key: true
      t.timestamps
    end
  end
end
