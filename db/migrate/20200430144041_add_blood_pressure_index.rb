class AddBloodPressureIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :blood_pressures, [:patient_id, :recorded_at], order: {patient_id: :asc, recorded_at: :desc}
  end
end
