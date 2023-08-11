class BulkApiImport::FhirObservationImporter
  include BulkApiImport::FhirImportable

  OBSERVATION_LOINC_CODES = {"85354-9" => :blood_pressure, "2339-0" => :blood_sugar}
  BP_LOINC_CODES = {"8480-6" => :systolic, "8462-4" => :diastolic}
  BS_LOINC_CODES = {"2339-0" => :random,
                    "87422-2" => :post_prandial,
                    "88365-2" => :fasting,
                    "4548-4" => :hba1c}

  def initialize(med_request_resource)
    @resource = med_request_resource
  end

  def import
  end

  def build_attributes
    {
      id: translate_id(@resource.dig(:identifier, 0, :value)),
      patient_id: @resource[:subject][:identifier],
      facility_id: translate_facility_id(@resource[:performer][0][:identifier]),
      user_id: import_user.id,
      recorded_at: @resource[:effectiveDateTime],
      **timestamps
    }.with_indifferent_access
  end
end
