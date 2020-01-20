class CreateMissingEncountersJob
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(blood_pressure_ids, timezone_offset)
    BloodPressure.where(id: blood_pressure_ids).each do |blood_pressure|
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
