class UpdatePatientSummariesToVersion2 < ActiveRecord::Migration[5.1]
  def change
    update_view :patient_summaries,
      version: 2,
      revert_to_version: 1,
      materialized: false
  end
end
