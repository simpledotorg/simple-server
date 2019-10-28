class MergeEncounterService
  def initialize(payload, facility, user, timezone_offset)
    @payload = payload
    @facility = facility
    @user = user
    @timezone_offset = timezone_offset
  end

  def merge
    Encounter.transaction do
      encounter_merge_params = payload.except(:observations).merge(facility: facility, timezone_offset: timezone_offset)
      encounter = Encounter.merge(encounter_merge_params)
      { encounter: encounter, observations: add_observations(encounter, payload[:observations]) }
    end
  end

  private

  attr_reader :payload, :facility, :user, :timezone_offset

  def add_observations(encounter, observation_params)
    {
      :blood_pressures =>
        observation_params[:blood_pressures].map do |params|
          blood_pressure = BloodPressure.merge(params)
          blood_pressure.find_or_update_observation!(encounter, user)
          blood_pressure
        end
    }
  end
end
