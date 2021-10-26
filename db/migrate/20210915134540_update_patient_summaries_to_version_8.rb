class UpdatePatientSummariesToVersion8 < ActiveRecord::Migration[5.2]
  def change
    update_view :patient_summaries, version: 8, revert_to_version: 7
  end
end
