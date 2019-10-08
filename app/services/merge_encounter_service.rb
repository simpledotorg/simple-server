class MergeEncounterService
  def initialize(payload, facility, timezone_offset)
    @payload = payload
    @facility = facility
    @timezone_offset = timezone_offset
  end

  def merge
    Encounter.transaction do
      encounter_merge_params = payload.except(:observations).merge(facility: facility,
                                                                   timezone_offset: timezone_offset)
      encounter = Encounter.merge(encounter_merge_params)
      { encounter: encounter, observations: create_observations!(encounter, payload[:observations]) }
    end
  end

  private

  attr_reader :payload, :facility, :timezone_offset

  def create_observations!(encounter, observations)
    observations[:blood_pressures].map do |bp|
      bp = BloodPressure.merge(bp)
      bp.create_observe!(encounter)
      bp
    end
  end
end
