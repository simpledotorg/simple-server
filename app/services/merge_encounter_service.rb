class MergeEncounterService
  def initialize(payload, facility)
    @payload = payload
    @facility = facility
  end

  def merge
    encounter_merge_params = payload
                               .except(:observations)
                               .merge(facility: facility,
                                      recorded_at: payload[:device_created_at])

    encounter = Encounter.merge(encounter_merge_params)
    create_observations!(encounter, payload[:observations])
    encounter
  end

  private

  attr_reader :payload, :facility

  def create_observations!(encounter, observations)
    observations[:blood_pressures].map do |bp|
      BloodPressure.merge(bp).create_observe!(encounter)
    end
  end
end
