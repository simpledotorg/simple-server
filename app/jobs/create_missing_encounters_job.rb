class CreateMissingEncountersJob
  include Sidekiq::Worker

  sidekiq_options queue: :audit_log_queue

  def perform(blood_pressure_ids, timezone_offset)
    blood_pressure_ids.each do |id|
      blood_pressure = BloodPressure.find_by(id: id)

      encountered_on = Encounter.generate_encountered_on(blood_pressure.recorded_at, timezone_offset)

      encounter_merge_params = {
        id: Encounter.generate_id(blood_pressure.facility_id, blood_pressure.patient_id, encountered_on),
        patient_id: blood_pressure.patient_id,
        facility_id: blood_pressure.facility_id,
        device_created_at: blood_pressure.device_created_at,
        device_updated_at: blood_pressure.device_updated_at,
        encountered_on: encountered_on,
        timezone_offset: timezone_offset,
        observations: {
          blood_pressures: [blood_pressure.attributes.except(:created_at, :updated_at)]
        }
      }.with_indifferent_access

      MergeEncounterService.new(encounter_merge_params, blood_pressure.user, timezone_offset).merge
    end
  end
end
