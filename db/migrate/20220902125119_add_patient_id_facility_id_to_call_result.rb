class AddPatientIdFacilityIdToCallResult < ActiveRecord::Migration[5.2]
  def change
    add_column :call_results, :patient_id, :uuid
    add_column :call_results, :facility_id, :uuid

    add_index :call_results, [:patient_id, :updated_at], name: :index_call_results_patient_id_and_updated_at
    add_index :call_results, :deleted_at, name: :index_call_results_deleted_at
  end
end
