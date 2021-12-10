class EstimatedPopulation < ApplicationRecord
  belongs_to :region

  validates :diagnosis, presence: true

  enum diagnosis: {HTN: "HTN", DM: "DM"}

  validate :can_only_be_set_for_district_or_state

  def can_only_be_set_for_district_or_state
    unless region.district_region? || region.state_region?
      errors.add(:region, "can only set population for a district or a state")
    end
  end

  def is_population_available_for_all_districts
    state = region.state_region
    is_population_available = false
    state&.district_regions&.each do |district|
      if district.estimated_population&.population
        is_population_available = true
      else
        is_population_available = false
        break
      end
    end
    is_population_available
  end
end
