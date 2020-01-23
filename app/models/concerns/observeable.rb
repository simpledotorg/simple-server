module Observeable
  extend ActiveSupport::Concern

  included do
    def find_or_update_observation!(encounter, user)
      build_observation(encounter: encounter, user: user) if observation.blank?
      observation.update!(encounter: encounter)
      observation
    end
  end
end
