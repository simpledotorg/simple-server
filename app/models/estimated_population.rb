class EstimatedPopulation < ApplicationRecord
  include Memery

  belongs_to :region

  validates :diagnosis, presence: true
  validates :population, presence: true

  enum diagnosis: {HTN: "HTN", DM: "DM"}

  validate :can_only_be_set_for_district_or_state

  def can_only_be_set_for_district_or_state
    unless region.district_region? || region.state_region?
      errors.add(:region, "can only set population for a district or a state")
    end
  end

  def hypertension_patient_coverage_rate
    population = region.estimated_population.population.to_f
    rate = (region.registered_patients.with_hypertension.count.to_f / population) * 100
    return nil if rate.infinite?
    return 100.0 if rate > 100.0
    return rate if rate > 0.0
  end

  def diabetes_patient_coverage_rate
    population = region.estimated_diabetes_population.population.to_f
    rate = (region.registered_patients.with_diabetes.count.to_f / population) * 100
    return nil if rate.infinite?
    return 100.0 if rate > 100.0
    return rate if rate > 0.0
  end

  def patient_coverage_rate(registered_patients)
    rate = (registered_patients.to_f / population) * 100
    return nil if rate.infinite?
    return 100.0 if rate > 100.0
    return rate if rate > 0.0
  end

  memoize def show_coverage(registered_patients = 0)
    if region.district_region?
      patient_coverage_rate(registered_patients).present?
    elsif region.state_region?
      region.estimated_population&.population_available_for_all_districts?
    else
      false
    end
  end

  def population_available_for_all_districts?
    state = region.state_region
    case diagnosis
    when "HTN"
      state.district_regions.includes(:estimated_population).all? { |district| district.estimated_population }
    when "DM"
      state.district_regions.includes(:estimated_diabetes_population).all? { |district| district.estimated_diabetes_population }
    end
  end
end
