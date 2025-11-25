class Dashboard::Diabetes::DmBpControlledComponent < ApplicationComponent
  attr_reader :data, :region, :period, :with_ltfu

  def initialize(data:, region:, period:, use_who_standard:, with_ltfu: false)
    @data = data
    @region = region
    @period = period
    @with_ltfu = with_ltfu
    @use_who_standard = use_who_standard
  end

  def graph_data
    # TODO: Replace with real data once backend is ready
    # Data structure: Each key maps to a hash where period keys (e.g., "Jul-2025") map to values
    # Example: { "Jul-2025" => 40.0, "Aug-2025" => 42.5, ... }
    rates_140, rates_130 = fake_controlled_bp_rates
    adjusted = fake_adjusted_patients

    {
      # Rates for BP controlled <140/90 (outer bar)
      controlledBPRate140: rates_140,
      # Rates for BP controlled <130/80 (inner bar, stacked on top)
      controlledBPRate130: rates_130,
      # Patient counts for BP controlled <140/90
      controlledBPNumerator140: calculate_numerators(rates_140, adjusted),
      # Patient counts for BP controlled <130/80
      controlledBPNumerator130: calculate_numerators(rates_130, adjusted),
      # Adjusted patient counts (denominator)
      adjustedPatients: adjusted,
      **period_data
    }
  end

  def bp_control_date_range
    "#{period.bp_control_range_start_date} to #{period.bp_control_range_end_date}"
  end

  private

  def period_data
    {
      startDate: fake_period_info(:bp_control_start_date),
      endDate: fake_period_info(:bp_control_end_date),
      registrationDate: fake_period_info(:bp_control_registration_date)
    }
  end

  def fake_period_info(key)
    # Generate fake period data for the last 18 months, ordered from oldest to newest
    (0..17).reverse_each.map do |i|
      period_date = period.value.advance(months: -i)
      period_key = period_date.strftime('%b-%Y')
      date_value = case key
                   when :bp_control_start_date
                     period_date.advance(months: -2).beginning_of_month.strftime('%d %b %Y')
                   when :bp_control_end_date
                     period_date.end_of_month.strftime('%d %b %Y')
                   when :bp_control_registration_date
                     period_date.advance(months: -3).end_of_month.strftime('%d-%b-%Y')
                   end
      [period_key, date_value]
    end.to_h
  end

  def fake_controlled_bp_rates
    # Generate both rates together to ensure rate140 > rate130 for each period
    # Both rates trend upward over time (older periods have lower rates)
    # Returns: [rates_140_hash, rates_130_hash] ordered from oldest to newest (left to right on chart)
    base_rate_140 = 50.0
    base_rate_130 = 30.0
    trend_increase_140 = 1.5 # percentage points per month
    trend_increase_130 = 1.2 # percentage points per month

    rates_140 = {}
    rates_130 = {}

    # Generate from oldest (17 months ago) to newest (current period) for correct chart display
    (0..17).reverse_each do |i|
      period_date = period.value.advance(months: -i)
      period_key = period_date.strftime('%b-%Y')

      # Generate rate140 with trend (older periods = lower rates)
      trended_rate_140 = base_rate_140 + (i * trend_increase_140) + rand(-2.0..2.0)
      rate_140 = [trended_rate_140, 40.0].max.round

      # Generate rate130 with trend, ensuring it's always lower than rate140
      trended_rate_130 = base_rate_130 + (i * trend_increase_130) + rand(-1.5..1.5)
      # Ensure rate130 is at least 15% lower than rate140, but not below 20%
      max_rate_130 = [rate_140 - 15.0, 20.0].max
      rate_130 = [[trended_rate_130, max_rate_130].min, 20.0].max.round

      rates_140[period_key] = rate_140
      rates_130[period_key] = rate_130
    end

    [rates_140, rates_130]
  end

  def calculate_numerators(rates, adjusted_patients)
    # Calculate numerators from rates and adjusted patient counts
    # Returns hash: { "Jul-2025" => 800, "Aug-2025" => 820, ... }
    rates.map do |period_key, rate|
      adjusted_count = adjusted_patients[period_key]
      numerator = (adjusted_count * rate / 100.0).round
      [period_key, numerator]
    end.to_h
  end

  def fake_adjusted_patients
    # Generate fake adjusted patient counts with a gradual trend
    # Starts around 1200 and gradually increases to ~1650 over 18 months
    # Returns hash ordered from oldest to newest (left to right on chart)
    base_count = 1200
    trend_increase = 25 # patients per month
    (0..17).reverse_each.map do |i|
      period_date = period.value.advance(months: -i)
      period_key = period_date.strftime('%b-%Y')
      # Older periods (higher i) have fewer patients, trending upward over time
      trended_count = base_count + (i * trend_increase) + rand(-50..50)
      [period_key, [trended_count, 800].max.round]
    end.to_h
  end
end
