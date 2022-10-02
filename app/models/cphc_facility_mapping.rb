class CphcFacilityMapping < ApplicationRecord
  belongs_to :facility, optional: true
end
