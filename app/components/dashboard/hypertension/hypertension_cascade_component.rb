class Dashboard::Hypertension::HypertensionCascadeComponent < ApplicationComponent
  attr_reader :data, :contactable, :period

  FIXED_RATE_WHEN_NO_ESTIMATE = "2%" # We show a fixed rate when there's no estimate for the region

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    @period = period
    @estimated_population = format(@region.estimated_population)
    @cumulative_registrations = format(data.dig(:cumulative_registrations, period))
    @under_care_patients = format(data.dig(:under_care, period))
    @controlled_patients = format(data.dig(:controlled_patients, period))
  end

  def cumulative_registrations_rate
    return FIXED_RATE_WHEN_NO_ESTIMATE unless show_estimate?
    number_to_percentage(@cumulative_registrations * 100 / @estimated_population.population, precision: 0)
  end

  def under_care_patients_rate
    return FIXED_RATE_WHEN_NO_ESTIMATE unless show_estimate?
    number_to_percentage(@under_care_patients * 100 / @estimated_population.population, precision: 0)
  end

  def controlled_patients_rate
    return FIXED_RATE_WHEN_NO_ESTIMATE unless show_estimate?
    number_to_percentage(@controlled_patients * 100 / @estimated_population.population, precision: 0)
  end

  def show_estimate?
    if @region.district_region?
      @estimated_population
    else
      @region.district_regions.all?(&:estimated_population)
    end
  end

  private

  def format(value)
    number_with_delimiter(value, delimiter: ",")
  end
end
