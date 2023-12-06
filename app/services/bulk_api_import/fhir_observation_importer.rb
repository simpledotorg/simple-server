class BulkApiImport::FhirObservationImporter
  include Api::V3::SyncEncounterObservation
  include BulkApiImport::FhirImportable

  OBSERVATION_LOINC_CODES = {"85354-9" => :blood_pressure, "2339-0" => :blood_sugar}
  BP_LOINC_CODES = {"8480-6" => :systolic, "8462-4" => :diastolic}
  BS_LOINC_CODES = {"2339-0" => :random,
                    "87422-2" => :post_prandial,
                    "88365-2" => :fasting,
                    "4548-4" => :hba1c}

  def initialize(resource:, organization_id:)
    @resource = resource
    @organization_id = organization_id
    @import_user = find_or_create_import_user(organization_id)
  end

  def import
    merge_result = case @resource[:code][:coding][0][:code].then { |code| OBSERVATION_LOINC_CODES[code] }
    when :blood_pressure
      import_blood_pressure
    when :blood_sugar
      import_blood_sugar
    else
      raise "unknown observation type"
    end

    AuditLog.merge_log(@import_user, merge_result) if merge_result.present?
    merge_result
  end

  def import_blood_pressure
    build_blood_pressure_attributes
      .then { Api::V3::BloodPressureTransformer.from_request(_1) }
      .then { merge_encounter_observation(:blood_pressures, _1) }
  end

  def import_blood_sugar
    build_blood_sugar_attributes
      .then { Api::V3::Transformer.from_request(_1) }
      .then { merge_encounter_observation(:blood_sugars, _1) }
  end

  def build_blood_pressure_attributes
    {
      id: translate_id(@resource.dig(:identifier, 0, :value), org_id: @organization_id),
      patient_id: translate_id(@resource[:subject][:identifier], org_id: @organization_id),
      facility_id: translate_facility_id(@resource[:performer][0][:identifier], org_id: @organization_id),
      user_id: @import_user.id,
      recorded_at: @resource[:effectiveDateTime],
      **dig_blood_pressure,
      **timestamps
    }.with_indifferent_access
  end

  def dig_blood_pressure
    @resource[:component].to_h do |component|
      type_of_reading = component[:code][:coding][0][:code].then { |bp_code| BP_LOINC_CODES[bp_code] }
      value_of_reading = component[:valueQuantity][:value]
      [type_of_reading, value_of_reading]
    end
  end

  def build_blood_sugar_attributes
    {
      id: translate_id(@resource.dig(:identifier, 0, :value), org_id: @organization_id),
      patient_id: translate_id(@resource[:subject][:identifier], org_id: @organization_id),
      facility_id: translate_facility_id(@resource[:performer][0][:identifier], org_id: @organization_id),
      user_id: @import_user.id,
      recorded_at: @resource[:effectiveDateTime],
      **dig_blood_sugar,
      **timestamps
    }.with_indifferent_access
  end

  def dig_blood_sugar
    component = @resource[:component][0]
    {
      blood_sugar_type: component[:code][:coding][0][:code]
        .then { |bs_code| BS_LOINC_CODES[bs_code] },
      blood_sugar_value: component[:valueQuantity][:value]
    }
  end

  # For compatibility with SyncEncounterObservation
  def current_timezone_offset
    0
  end

  # For compatibility with SyncEncounterObservation
  def current_user
    @import_user
  end
end
