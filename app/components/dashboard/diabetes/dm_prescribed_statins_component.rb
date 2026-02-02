class Dashboard::Diabetes::DmPrescribedStatinsComponent < ApplicationComponent
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
      rates = data[:dm_prescribed_statins_with_ltfu_rates]
      denominator = data[:dm_patients_40_and_above_with_ltfu]
    else
      rates = data[:dm_prescribed_statins_rates]
      denominator = data[:dm_patients_40_and_above_under_care]
    end

    {
      prescribedStatinsRate: format_rates(rates),
      prescribedStatinsNumerator: format_counts(data[:dm_patients_prescribed_statins]),
      cumulativeAssignedPatientsUnderCareOver40yearsOld: format_counts(denominator),
      **period_data
    }
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
