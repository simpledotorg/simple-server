class MergeEncounterService
  def initialize(payload, facility)
    @payload = payload
    @facility = facility
  end

  def merge
    encounter_merge_params = payload
                               .except(:observations)
                               .merge(facility: facility,
                                      encountered_on:
                                        Encounter.generate_encountered_on(payload[:recorded_at], 3600))

    encounter = Encounter.merge(encounter_merge_params)

    {
      encounter: encounter,
      observations: create_observations!(encounter, payload[:observations])
    }
  end

  private

  attr_reader :payload, :facility

  def create_observations!(encounter, observations)
    observations[:blood_pressures].map do |bp|
      bp = BloodPressure.merge(bp)
      bp.create_observe!(encounter)
      bp
    end
  end
end
