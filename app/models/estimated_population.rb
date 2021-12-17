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

  def hypertension_patient_coverage_rate
    population = region.estimated_population.population.to_f
    rate = (region.registered_patients.with_hypertension.count.to_f / population) * 100
    return nil if rate.infinity?
    return 100.0 if rate > 100.0
    return rate if rate > 0.0
  end

  def show_coverage
    show_coverage = false

    if region.district_region? && region.estimated_population&.hypertension_patient_coverage_rate
      show_coverage = true
    elsif region.state_region? && region.estimated_population&.is_population_available_for_all_districts
      show_coverage = true
    end

    show_coverage
  end
end
