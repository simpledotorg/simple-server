class AddScheduledDateIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :appointments, [:patient_id, :scheduled_date], order: {patient_id: :asc, scheduled_date: :desc}
  end
end
