# frozen_string_literal: true

class MergeEncounterService
  OBSERVATION_NAMES = [:blood_pressures, :blood_sugars].freeze

  def initialize(payload, user, timezone_offset)
    @payload = payload
    @user = user
    @timezone_offset = timezone_offset
  end

  def merge
    Encounter.transaction do
      encounter_merge_params = payload.except(:observations).merge(timezone_offset: timezone_offset)
      encounter = Encounter.merge(encounter_merge_params)
      {encounter: encounter, observations: add_observations(encounter, payload[:observations])}
    end
  end

  private

  attr_reader :payload, :user, :timezone_offset

  def add_observations(encounter, observation_params)
    OBSERVATION_NAMES.map { |key|
      next nil if observation_params[key].blank?

      observations = observation_params[key].map { |params|
        record = key.to_s.classify.constantize.merge(params)
        record.find_or_update_observation!(encounter, user)
        record
      }
      [key, observations]
    }.compact.to_h
  end
end
