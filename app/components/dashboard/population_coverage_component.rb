class Dashboard::PopulationCoverageComponent < ApplicationComponent
  attr_reader :region
  attr_reader :cumulative_registrations
  attr_reader :diagnosis
  attr_reader :estimated_population
  attr_reader :current_admin
  attr_reader :tooltip_copy

  def initialize(region:, cumulative_registrations:, diagnosis:, estimated_population:, current_admin:, tooltip_copy:)
    @region = region
    @cumulative_registrations = cumulative_registrations
    @estimated_population = estimated_population
    @diagnosis = diagnosis
    @current_admin = current_admin
    @tooltip_copy = tooltip_copy
  end

  def accessible_region?(region, action)
    return true if region.region_type == "facility"
    helpers.accessible_region?(region, action)
  end

  def show_coverage
    return false unless estimated_population.present?
    estimated_population.show_coverage(cumulative_registrations)
  end

  def patient_coverage_rate
    return nil unless estimated_population.present?
    estimated_population.patient_coverage_rate(cumulative_registrations)
  end

  def population_coverage_percentage
    return 0 unless estimated_population.present?
    number_to_percentage(estimated_population.patient_coverage_rate(cumulative_registrations), precision: 0)
  end
end
