class Dashboard::Diabetes::BsOver200GraphComponent < ApplicationComponent
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

  def graph_data
    if with_ltfu
      return {
        adjustedPatients: data[:adjusted_diabetes_patient_counts_with_ltfu],
        bs200to300Numerator: data[:bs_200_to_300_patients],
        bs200to300Rate: data[:bs_200_to_300_with_ltfu_rates],
        bsOver300Numerator: data[:bs_over_300_patients],
        bsOver300Rate: data[:bs_over_300_with_ltfu_rates],
        **period_data,
        **breakdown_rates
      }
    end

    {
      adjustedPatients: data[:adjusted_diabetes_patient_counts],
      bs200to300Numerator: data[:bs_200_to_300_patients],
      bs200to300Rate: data[:bs_200_to_300_rates],
      bsOver300Numerator: data[:bs_over_300_patients],
      bsOver300Rate: data[:bs_over_300_rates],
      **period_data,
      **breakdown_rates
    }
  end

  def denominator_copy
    with_ltfu ? "diabetes_denominator_with_ltfu_copy" : "diabetes_denominator_copy"
  end

  def period_data
    {
      startDate: period_info(:bp_control_start_date),
      endDate: period_info(:bp_control_end_date),
      registrationDate: period_info(:bp_control_registration_date)
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end

  def breakdown_rates
    {}
  end
end
