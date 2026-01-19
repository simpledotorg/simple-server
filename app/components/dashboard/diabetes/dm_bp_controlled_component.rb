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
    if with_ltfu
      adjusted_patients_data = data[:adjusted_diabetes_patient_counts_with_ltfu]
      rates_140 = data[:dm_controlled_bp_140_90_with_ltfu_rates]
      rates_130 = data[:dm_controlled_bp_130_80_with_ltfu_rates]
    else
      adjusted_patients_data = data[:adjusted_diabetes_patient_counts]
      rates_140 = data[:dm_controlled_bp_140_90_rates]
      rates_130 = data[:dm_controlled_bp_130_80_rates]
    end

    numerators_140 = data[:dm_patients_with_controlled_bp_140_90]
    numerators_130 = data[:dm_patients_with_controlled_bp_130_80]

    {
      # Rates for BP controlled <140/90 (outer bar)
      controlledBPRate140: format_rates(rates_140),
      # Rates for BP controlled <130/80 (inner bar, stacked on top)
      controlledBPRate130: format_rates(rates_130),
      # Patient counts for BP controlled <140/90
      controlledBPNumerator140: format_counts(numerators_140),
      # Patient counts for BP controlled <130/80
      controlledBPNumerator130: format_counts(numerators_130),
      # Adjusted patient counts (denominator)
      adjustedPatients: format_counts(adjusted_patients_data),
      **period_data
    }
  end

  def bp_control_date_range
    "#{period.bp_control_range_start_date} to #{period.bp_control_range_end_date}"
  end

  private

  def period_data
    {
      startDate: period_info(:bp_control_start_date),
      endDate: period_info(:bp_control_end_date),
      registrationDate: period_info(:bp_control_registration_date)
    }
  end

  def period_info(key)
    data[:period_info].map do |period_obj, period_data_hash|
      period_key = period_obj.to_s
      date_value = period_data_hash[key]
      [period_key, date_value]
    end.to_h
  end

  def format_rates(rates_hash)
    rates_hash.transform_keys { |period| period.to_s }
  end

  def format_counts(counts_hash)
    counts_hash.transform_keys { |period| period.to_s }
  end
end
