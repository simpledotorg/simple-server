class AddIndexOnIdentifiersInPatientBusinessIdentifier < ActiveRecord::Migration[5.2]
  def change
    add_index :patient_business_identifiers, :identifier, name: "index_patient_business_identifiers_identifier"
  end
end
