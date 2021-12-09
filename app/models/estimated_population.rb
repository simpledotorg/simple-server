class EstimatedPopulation < ApplicationRecord
  belongs_to :region

  validates :population, numericality: true, presence: true
  validates :diagnosis, presence: true

  enum diagnosis: {HTN: "HTN", DM: "DM"}

  validate :can_only_be_set_for_district_or_state
  after_commit :update_state_population

  def can_only_be_set_for_district_or_state
    region_type = region.region_type

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

  def update_state_population
    if region.district_region?
      state = region.state_region
      state_population = 0
      state&.district_regions&.each do |district|
        state_population += district.reload_estimated_population&.population || 0
      end
      if state.estimated_population
        state.estimated_population.population = state_population
        state.estimated_population.save!
      else
        state.create_estimated_population(population: state_population)
      end
    end
  end
end
