class FacilityStatsService

  attr_reader :facilities, :ending_period, :rate_numerator, :facilities_data, :stats_by_size

  def initialize(facilities, ending_period, rate_numerator)
    @facilities = facilities
    @ending_period = ending_period
    @rate_numerator = rate_numerator
    @facilities_data = {}
    @stats_by_size = {}
  end

  def call
    facilities.each do |facility|
      facility_data = Reports::RegionService.new(region: facility, period: ending_period).call
      add_facility_stats(facility_data)
      @facilities_data[facility.name] = facility_data
    end
    add_control_rates
  end

  private

  def add_facility_stats(facility_data)
    size = facility_data.region.facility_size
    add_size_section(size) unless stats_by_size[size]
    periods.each do |period|
      current_period = stats_by_size[size][period]
      current_period[rate_numerator] += facility_data[rate_numerator][period]
      current_period['adjusted_registrations'] += facility_data['adjusted_registrations'][period]
      current_period['cumulative_registrations'] += facility_data['cumulative_registrations'][period]
    end
  end

  def add_control_rates
    stats_by_size.each_pair do |_, period_sets|
      period_sets.each_pair do |_, period_stats|
        adjusted_registrations = period_stats['adjusted_registrations']
        next if adjusted_registrations == 0
        period_stats['control_rate'] = (period_stats[rate_numerator].to_f / adjusted_registrations.to_f * 100).round
      end
    end
  end

  def periods
    @periods ||= ending_period.downto(5)
  end

  def add_size_section(size)
    stats_by_size[size] = size_data_template
  end

  def size_data_template
    periods.reduce({}) do |hsh, period|
      hsh[period] = month_data_template
      hsh
    end
  end

  def month_data_template
    {
      rate_numerator => 0,
      'adjusted_registrations' => 0,
      'cumulative_registrations' => 0,
      'control_rate' => 0,
    }
  end
end