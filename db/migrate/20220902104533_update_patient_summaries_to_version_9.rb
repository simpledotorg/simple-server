class UpdatePatientSummariesToVersion9 < ActiveRecord::Migration[5.2]
  def change
    update_view :patient_summaries, version: 9, revert_to_version: 8
  end
end
