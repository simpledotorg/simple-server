class FacilityStatsService
  attr_reader :stats_by_size

  def initialize(facilities:, period:, rate_numerator: nil)
    @facilities = facilities
    @period = period
    @periods = period.downto(5)
    @rate_numerator = rate_numerator
    @rate_name = "#{rate_numerator}_rate".to_sym
    @stats_by_size = {}
  end

  def self.call(facilities:, period:, rate_numerator: nil)
    new(facilities: facilities, period: period, rate_numerator: rate_numerator).call
  end

  def call
    facilities.values.each do |facility_data|
      add_facility_stats(facility_data)
    end
    calculate_percentages
    stats_by_size
  end

  private

  attr_reader :facilities, :rate_numerator, :rate_name, :periods

  def add_facility_stats(facility_data)
    size = facility_data[:facility_size]
    add_size_section(size) unless stats_by_size[size]
    periods.each do |period|
      current_period = stats_by_size[size][:periods][period]

      if rate_numerator.nil?
        current_period[:controlled_patients] += facility_data.dig(:controlled_patients, period) || 0
        current_period[:uncontrolled_patients] += facility_data.dig(:uncontrolled_patients, period) || 0
        current_period[:missed_visits] += facility_data.dig(:missed_visits, period) || 0
      else
        current_period[rate_numerator] += facility_data.dig(rate_numerator, period) || 0
      end

      current_period[:adjusted_patient_counts] += facility_data[:adjusted_patient_counts][period]
      current_period[:cumulative_registrations] += facility_data[:cumulative_registrations][period]
      current_period[:cumulative_assigned_patients] += facility_data[:cumulative_assigned_patients][period]
    end
  end

  def calculate_percentages
    stats_by_size.values.each do |size_data|
      size_data[:periods].values.each do |period_stats|
        adjusted_patient_counts = period_stats[:adjusted_patient_counts]
        next if adjusted_patient_counts == 0
        if rate_numerator.nil?
          period_stats[:controlled_patients_rate] = (period_stats[:controlled_patients].to_f / adjusted_patient_counts.to_f * 100).round
          period_stats[:uncontrolled_patients_rate] = (period_stats[:uncontrolled_patients].to_f / adjusted_patient_counts.to_f * 100).round
          period_stats[:missed_visits_rate] = (period_stats[:missed_visits].to_f / adjusted_patient_counts.to_f * 100).round
        else
          next if period_stats[rate_numerator] == 0
          period_stats[rate_name] = (period_stats[rate_numerator].to_f / adjusted_patient_counts.to_f * 100).round
        end
      end
    end
  end

  def add_size_section(size)
    stats_by_size[size] = {
      periods: size_data_template
    }
  end

  def size_data_template
    periods.reverse.each_with_object({}) do |period, hsh|
      hsh[period] = {
        adjusted_patient_counts: 0,
        cumulative_assigned_patients: 0,
        cumulative_registrations: 0
      }

      if rate_numerator.nil?
        hsh[period].merge!({
          controlled_patients_rate: 0,
          controlled_patients: 0,
          uncontrolled_patients: 0,
          uncontrolled_patients_rate: 0,
          missed_visits: 0,
          missed_visits_rate: 0
        })
      else
        hsh[period].merge!({
          rate_name => 0,
          rate_numerator => 0
        })
      end

      hsh[period]
    end
  end
end
