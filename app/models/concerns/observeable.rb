module Observeable
  extend ActiveSupport::Concern

  included do
    def find_or_update_observation!(encounter, user)
      build_observation(encounter: encounter, user: user) if observation.blank?
      observation && observation.update!(encounter: encounter, updated_at: updated_at)
      observation
    end
  end
end
