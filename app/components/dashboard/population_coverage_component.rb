class Dashboard::PopulationCoverageComponent < ApplicationComponent
  include DashboardHelper

  attr_reader :region, :data, :current_admin

  def initialize(region:, data:, current_admin:)
    @region = region
    @data = data
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

  def total_registered_patients
    data.dig(:patient_breakdown, :total_registered_patients)
  end

  def total_assigned_patients
    data.dig(:patient_breakdown, :total_assigned_patients)
  end

  def population_coverage_percentage
    number_to_percentage(@region.estimated_diabetes_population.diabetes_patient_coverage_rate, precision: 0)
  end
end
