class CreatePatientSummaries < ActiveRecord::Migration[5.1]
  def change
    create_view :patient_summaries
  end
end
