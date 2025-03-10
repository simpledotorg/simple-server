class EnablePatientSummariesV3ForEthiopia < ActiveRecord::Migration[6.1]
  def change
    if CountryConfig.current_country?("Ethiopia")
      update_view :materialized_patient_summaries,
        version: 3,
        revert_to_version: 2,
        materialized: true
    end
  end
end
