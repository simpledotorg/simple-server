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

  def hypertension_patient_coverage
    population = region.estimated_population.population.to_f
    if population > 100
      return "100%"
    elsif population > 0
      return number_to_percentage((region.registered_patients.count.to_f / population) * 100, precision: 0)
    end
  end

  def show_coverage
    if region.district_region? && region.estimated_population.hypertension_patient_coverage
      return true
    elsif region.state_region? && region.estimated_population.is_population_available_for_all_districts
      return true
    else
      return false
    end
  end
end
