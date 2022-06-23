class Dashboard::PopulationCoverageComponent < ApplicationComponent
  include DashboardHelper

  attr_reader :region
  attr_reader :data
  attr_reader :diagnosis
  attr_reader :estimated_population
  attr_reader :current_admin

  def initialize(region:, data:, diagnosis:, estimated_population:, current_admin:)
    @region = region
    @data = data
    @estimated_population = estimated_population
    @diagnosis = diagnosis
    @current_admin = current_admin
  end

  def accessible_region?(region, action)
    case region.region_type
    when "facility"
      true
    else
      helpers.accessible_region?(region, action)
    end
  end

  def cumulative_registrations
    data[:cumulative_registrations]
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
    number_to_percentage(@region.estimated_diabetes_population.diabetes_patient_coverage_rate, precision: 0)
  end

  def total_estimated_population_tooltip_copy
    case diagnosis
    when :hypertension
      total_estimated_hypertensive_population_copy(region)
    when :diabetes
      total_estimated_diabetic_population_copy(region)
    end
  end
end
