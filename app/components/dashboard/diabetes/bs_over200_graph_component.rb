class Dashboard::Diabetes::BsOver200GraphComponent < ApplicationComponent
  attr_reader :data
  attr_reader :region
  attr_reader :period
  attr_reader :with_ltfu

  def initialize(data:, region:, period:, use_who_standard:, with_ltfu: false)
    @data = data
    @region = region
    @period = period
    @with_ltfu = with_ltfu
    @use_who_standard = use_who_standard
  end

 # Sum two same-shaped series.
  # Accepts either the series themselves (Hash/Array) OR the Symbol keys to look them up in `data`.
  def sum_series(a, b)
    a = data[a] if a.is_a?(Symbol)
    b = data[b] if b.is_a?(Symbol)

    if a.is_a?(Hash)
      a.merge(b) { |_k, x, y| x.to_f + y.to_f }
    else
      a.zip(b).map { |x, y| x.to_f + y.to_f }
    end
  end

  def graph_data
    if with_ltfu
      return {
        adjustedPatients: data[:adjusted_diabetes_patient_counts_with_ltfu],
        bs200to300Numerator: data[:bs_200_to_300_patients],
        bs200to300Rate: data[:bs_200_to_300_with_ltfu_rates],
        bsOver300Numerator: data[:bs_over_300_patients],
        bsOver300Rate: data[:bs_over_300_with_ltfu_rates],
        bsOver200Rate: sum_series(:bs_200_to_300_with_ltfu_rates, :bs_over_300_with_ltfu_rates),
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
      bsOver200Rate: sum_series(:bs_200_to_300_rates, :bs_over_300_rates),
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
