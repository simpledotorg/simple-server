class Dashboard::Hypertension::BpUncontrolledGraphComponent < ApplicationComponent
  attr_reader :data, :region, :period, :with_ltfu

  def initialize(data:, region:, period:, with_ltfu:)
    @data = data
    @region = region
    @period = period
    @with_ltfu = with_ltfu
  end

  def graph_data
    if with_ltfu
      return {
        adjustedPatientCounts: data[:adjusted_patient_counts_with_ltfu],
        uncontrolledPatients: data[:uncontrolled_patients],
        uncontrolledRate: data[:uncontrolled_patients_with_ltfu_rate],
        **period_data
      }
    end

    {adjustedPatientCounts: data[:adjusted_patient_counts],
     uncontrolledPatients: data[:uncontrolled_patients],
     uncontrolledRate: data[:uncontrolled_patients_rate],
     **period_data}
  end


  def denominator_copy
    with_ltfu ? "denominator_with_ltfu_copy" : "denominator_copy"
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
end
