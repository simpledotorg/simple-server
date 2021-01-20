class CreateMaterializedPatientSummaries < ActiveRecord::Migration[5.2]
  def change
    create_view :materialized_patient_summaries, materialized: true
  end
end
