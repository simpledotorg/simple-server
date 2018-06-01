class CreateBloodPressure < ActiveRecord::Migration[5.1]
  def change
    create_table :blood_pressures, id: false do |t|
      t.uuid :id, primary_key: true
      t.integer :systolic, null: false
      t.integer :diastolic, null: false
      t.uuid :patient_id, null: false
      t.timestamps
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
    end
  end
end
