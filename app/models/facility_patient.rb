class FacilityPatient < ApplicationRecord
  belongs_to :facility
  belongs_to :patient
end
