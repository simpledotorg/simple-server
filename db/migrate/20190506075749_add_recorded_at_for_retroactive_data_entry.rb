class AddRecordedAtForRetroactiveDataEntry < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :recorded_at, :timestamp, null: true
    add_column :appointments, :recorded_at, :timestamp, null: true
    add_column :blood_pressures, :recorded_at, :timestamp, null: true
    add_column :communications, :recorded_at, :timestamp, null: true
    add_column :medical_histories, :recorded_at, :timestamp, null: true
    add_column :patients, :recorded_at, :timestamp, null: true
    add_column :patient_business_identifiers, :recorded_at, :timestamp, null: true
    add_column :patient_phone_numbers, :recorded_at, :timestamp, null: true
    add_column :prescription_drugs, :recorded_at, :timestamp, null: true

    # do we need indexes?
  end
end
