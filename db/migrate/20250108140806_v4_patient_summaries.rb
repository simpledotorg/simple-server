class V4PatientSummaries < ActiveRecord::Migration[6.1]
  def change
    revert_version = 3
    revert_version = 2 if CountryConfig.current_country?("Ethiopia")
    update_view :materialized_patient_summaries,
      version: 4,
      revert_to_version: revert_version,
      materialized: true
  end
end
