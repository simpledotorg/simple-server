class UpdatePatientSummariesToVersion7 < ActiveRecord::Migration[5.2]
  def change
    update_view :patient_summaries, version: 7, revert_to_version: 6
  end
end
