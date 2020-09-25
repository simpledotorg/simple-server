class AddIndicesToMatviews < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :latest_blood_pressures_per_patient_per_months, :assigned_facility_id, name: "index_bp_months_assigned_facility_id", algorithm: :concurrently
  end
end
