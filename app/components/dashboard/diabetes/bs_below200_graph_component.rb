class Dashboard::Diabetes::BsBelow200GraphComponent < ApplicationComponent
  attr_reader :data
  attr_reader :region
  attr_reader :period
  attr_reader :with_ltfu

  def initialize(data:, region:, period:, with_ltfu: false)
    @data = data
    @region = region
    @period = period
    @with_ltfu = with_ltfu
  end

  def denominator_copy
    with_ltfu ? "diabetes_denominator_with_ltfu_copy" : "diabetes_denominator_copy"
  end

  def graph_data
    if with_ltfu
      return {
        adjustedPatients: data[:adjusted_diabetes_patient_counts_with_ltfu],
        bsBelow200Numerator: data[:bs_below_200_patients],
        bsBelow200Rate: data[:bs_below_200_with_ltfu_rates],
        **period_data,
        **breakdown_rates
      }
    end

    {
      adjustedPatients: data[:adjusted_diabetes_patient_counts],
      bsBelow200Numerator: data[:bs_below_200_patients],
      bsBelow200Rate: data[:bs_below_200_rates],
      **period_data,
      **breakdown_rates
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

  def breakdown_rates
    {
      rbsPpbsBreakdownRates: data[:bs_below_200_breakdown_rates].map { |period, value| [period, value[:random] + value[:post_prandial]] }.to_h,
      fbsBreakdownRates: data[:bs_below_200_breakdown_rates].map { |period, value| [period, value[:fasting]] }.to_h,
      hba1cBreakdownRates: data[:bs_below_200_breakdown_rates].map { |period, value| [period, value[:hba1c]] }.to_h
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end
end
