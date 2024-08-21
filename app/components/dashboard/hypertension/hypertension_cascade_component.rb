class Dashboard::Hypertension::HypertensionCascadeComponent < ApplicationComponent
  attr_reader :data, :contactable, :period

  FIXED_RATE_WHEN_NO_ESTIMATE = "2%" # We show a fixed rate when there's no estimate for the region

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    @period = period
    @estimated_population = @region.estimated_population
    @cumulative_registrations = data.dig(:cumulative_registrations, period)
    @under_care_patients = data.dig(:under_care, period)
    @controlled_patients = data.dig(:controlled_patients, period)
  end

  def cumulative_registrations_rate
    return FIXED_RATE_WHEN_NO_ESTIMATE unless show_estimate?
    number_to_percentage(@cumulative_registrations * 100 / estimated_population_count, precision: 0)
  end

  def under_care_patients_rate
    return FIXED_RATE_WHEN_NO_ESTIMATE unless show_estimate?
    number_to_percentage(@under_care_patients * 100 / estimated_population_count, precision: 0)
  end

  def controlled_patients_rate
    return FIXED_RATE_WHEN_NO_ESTIMATE unless show_estimate?
    number_to_percentage(@controlled_patients * 100 / estimated_population_count, precision: 0)
  end

  def estimated_population_count
    if @region.organization_region?
      @region.state_regions.map(&:estimated_population).map(&:population).sum
    else
      @estimated_population.population
    end
  end

  def show_estimate?
    if @region.district_region?
      @estimated_population
    else
      @region.district_regions.all?(&:estimated_population)
    end
  end

  def period_end
    period.end.to_s(:day_mon_year)
  end
end
