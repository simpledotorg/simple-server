class CreateReminderExperiments < ActiveRecord::Migration[5.2]
  def change
    create_table :reminder_experiments do |t|
      t.boolean :active, null: false
      t.date :start_date, null: true
      t.date :end_date, null: true
      t.timestamps null: false
    end
  end
end
