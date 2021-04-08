module Experimentation
  class TreatmentGroupMembership < ActiveRecord::Base
    belongs_to :treatment_group
    belongs_to :patient
  end
end
