# frozen_string_literal: true

#
# This concern is different from the association `Observable` or the Rails `Observable` pattern
# Hence, it is named `Observeable` to avoid conflicts
#
module Observeable
  extend ActiveSupport::Concern

  included do
    def find_or_update_observation!(encounter, user)
      with_discarded_observations do
        build_observation(encounter: encounter, user: user) if observation.blank?
        observation.update!(encounter: encounter)
        observation
      end
    end
  end

  private

  def with_discarded_observations
    Observation.unscoped { yield }
  end
end
