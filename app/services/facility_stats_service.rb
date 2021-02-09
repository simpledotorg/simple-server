class FacilityStatsService
  attr_reader :stats_by_size

  def initialize(facilities:, ending_period:, rate_numerator:)
    @facilities = facilities
    @ending_period = ending_period
    @rate_numerator = rate_numerator
    @rate_name = "#{rate_numerator}_rate"
    @periods = ending_period.downto(5)
    @stats_by_size = {}.with_indifferent_access
  end

  def self.call(facilities:, ending_period:, rate_numerator:)
    new(facilities: facilities, ending_period: ending_period, rate_numerator: rate_numerator).call
  end

  def call
    facilities.each_pair do |_, facility_data|
       add_facility_stats(facility_data)
       add_registrations_count(facility_data.region.source)
    end
    calculate_percentages
    stats_by_size
  end

  private

  attr_reader :facilities, :rate_numerator, :rate_name, :periods

  def add_facility_stats(facility_data)
    size = facility_data.region.source.facility_size
    add_size_section(size) unless stats_by_size[size]
    periods.each do |period|
      current_period = stats_by_size[size][:periods][period]
      current_period[rate_numerator] += facility_data.dig(rate_numerator, period) || 0
      current_period[:adjusted_registrations] += facility_data[:adjusted_registrations][period]
      current_period["cumulative_registrations"] += facility_data["cumulative_registrations"][period]
# binding.pry
    end
  end

  def calculate_percentages
    stats_by_size.each_pair do |_size, size_data|
      size_data[:periods].each_pair do |_period, period_stats|
        adjusted_registrations = period_stats["adjusted_registrations"]
        next if adjusted_registrations == 0 || period_stats[rate_numerator] == 0
        period_stats[rate_name] = (period_stats[rate_numerator].to_f / adjusted_registrations.to_f * 100).round
      end
    end
  end

  def add_registrations_count(facility)
    stats_by_size[facility.facility_size][:total_registered_patients] += facility.registered_hypertension_patients.count
  end

  def add_size_section(size)
    stats_by_size[size] = { periods: period_data_template, total_registered_patients: 0 }.with_indifferent_access
  end

  def period_data_template
    periods.reverse.inject({}) do |hsh, period|
      hsh[period] = {
        rate_numerator => 0,
        "adjusted_registrations" => 0,
        "cumulative_registrations" => 0,
        rate_name => 0
      }.with_indifferent_access
      hsh
    end
  end
end
