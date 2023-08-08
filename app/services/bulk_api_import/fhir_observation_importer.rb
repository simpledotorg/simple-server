class BulkApiImport::FhirObservationImporter
  include Api::V3::SyncEncounterObservation
  include BulkApiImport::FhirImportable

  OBSERVATION_LOINC_CODES = {"85354-9" => :blood_pressure}
  BP_LOINC_CODES = {"8480-6" => :systolic, "8462-4" => :diastolic}

  def initialize(observation_resource)
    @resource = observation_resource
  end

  def import
    case @resource[:code][:coding][0][:code].then { |code| OBSERVATION_LOINC_CODES[code] }
    when :blood_pressure
      import_blood_pressure
    when :blood_sugar
      import_blood_sugar
    else
      raise "unknown observation type"
    end
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
      id: translate_id(@resource.dig(:identifier, 0, :value)),
      systolic: dig_blood_pressure[:systolic],
      diastolic: dig_blood_pressure[:diastolic],
      patient_id: @resource[:subject][:identifier],
      facility_id: translate_facility_id(@resource[:performer][0][:identifier]),
      user_id: import_user,
      recorded_at: @resource[:effectiveDateTime],
      **timestamps
    }.with_indifferent_access
  end

  def dig_blood_pressure
    @blood_pressure ||= @resource[:component].to_h do |component|
      type_of_reading = component[:code][:coding][0][:code].then { |bp_code| BP_LOINC_CODES[bp_code] }
      value_of_reading = component[:valueQuantity][:value]
      [type_of_reading, value_of_reading]
    end
  end

  def build_blood_sugar_attributes
  end

  # For compatibility with SyncEncounterObservation
  def current_timezone_offset
    0
  end

  # For compatibility with SyncEncounterObservation
  def current_user
    import_user
  end
end
