class AddPatientIdIndexToMaterializedPatientSummary < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :materialized_patient_summaries, :id, algorithm: :concurrently
  end
end
