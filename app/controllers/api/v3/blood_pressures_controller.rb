class Api::V3::BloodPressuresController < Api::V3::SyncController
  include Api::V3::PrioritisableByFacility
  include Api::V3::SyncEncounterObservation
  include Api::V3::RetroactiveDataEntry

  def sync_from_user
    __sync_from_user__(blood_pressures_params)
  end

  def sync_to_user
    __sync_to_user__("blood_pressures")
  end

  private

  def merge_if_valid(bp_params)
    validator = Api::V3::BloodPressurePayloadValidator.new(bp_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric("Merge/BloodPressure/schema_invalid")
      {errors_hash: validator.errors_hash}
    else
      set_patient_recorded_at(bp_params)
      transformed_params = Api::V3::BloodPressureTransformer.from_request(bp_params)
      {record: merge_encounter_observation(:blood_pressures, transformed_params)}
    end
  end

  def after_merge_completed(results)
    records = results.flat_map { |r| r[:record] }.compact
    send_to_job(records)
  end

  def send_to_job(records)
    records.each do |record|
      attrs = {
        assigned_facility_id: record.patient.registration_facility_id,
        blood_pressure_facility_id: record.facility_id,
        blood_pressure_id: record.id,
        diastolic: record.diastolic,
        patient_id: record.patient_id,
        recorded_at: record.recorded_at,
        systolic: record.systolic,
      }
      puts "attrs for rollup: #{attrs}"
      BloodPressureRollup.create!(attrs)
    end
  end

  def transform_to_response(blood_pressure)
    Api::V3::Transformer.to_response(blood_pressure)
  end

  def blood_pressures_params
    params.require(:blood_pressures).map do |blood_pressure_params|
      blood_pressure_params.permit(
        :id,
        :systolic,
        :diastolic,
        :patient_id,
        :facility_id,
        :user_id,
        :created_at,
        :updated_at,
        :recorded_at,
        :deleted_at
      )
    end
  end
end
