class CohortAnalyticsQuery
  include QuarterHelper

  attr_reader :from_time
  attr_reader :period
  attr_reader :prev_periods

  def initialize(facilities, period: :month, prev_periods: nil, from_time: Time.current)
    @facilities = facilities
    @patients = Patient.joins(:registration_facility).where(facilities: {id: facilities}).with_hypertension
    @from_time = from_time
    @period = period

    @include_current_period = true
    @prev_periods = if prev_periods.nil?
      @period == :quarter ? 5 : 6
    else
      prev_periods
    end
  end

  def patient_counts_by_period
    results = {}

    # index is a quick hack to allow toggling the current period in the results.
    index = @include_current_period ? -1 : 0
    (index..(prev_periods - 1 + index)).each do |periods_back|
      if period == :month
        offset_date = from_time - periods_back.months
        cohort_start = (offset_date - 3.months).beginning_of_month
        cohort_end = cohort_start.end_of_month
        report_start = (cohort_start + 1.month).beginning_of_month
        report_end = (report_start + 1.month).end_of_month
      else
        offset_date = from_time - (periods_back * 3).months
        cohort_start = (offset_date - 6.months).beginning_of_quarter
        cohort_end = cohort_start.end_of_quarter
        report_start = (cohort_start + 3.months).beginning_of_quarter
        report_end = report_start.end_of_quarter
      end

      results[[cohort_start.to_date, report_start.to_date]] = patient_counts(cohort_start, cohort_end, report_start, report_end)
    end

    results
  end

  def patient_counts(cohort_start, cohort_end, report_start, report_end)
    registered_patients = registered(cohort_start, cohort_end)
    followed_up_patients = followed_up(registered_patients, report_start, report_end)
    controlled_patients = controlled(followed_up_patients)
    uncontrolled_patients = followed_up_patients - controlled_patients

    registered_counts = registered_patients.group(:registration_facility_id).size.symbolize_keys
    followed_up_counts = followed_up_patients.group(:registration_facility_id).size.symbolize_keys
    defaulted_counts = registered_counts.merge(followed_up_counts) { |_, registered, followed_up|
      registered - followed_up
    }

    controlled_counts = controlled_patients.group(:registration_facility_id).size.symbolize_keys
    uncontrolled_counts = followed_up_counts.merge(controlled_counts) { |_, followed_up, controlled|
      followed_up - controlled
    }

    {
      registered: {total: registered_patients.size, **registered_counts},
      followed_up: {total: followed_up_patients.size, **followed_up_counts},
      defaulted: {total: registered_patients.size - followed_up_patients.size, **defaulted_counts},
      controlled: {total: controlled_patients.size, **controlled_counts},
      uncontrolled: {total: uncontrolled_patients.size, **uncontrolled_counts}
    }.with_indifferent_access
  end

  def registered(cohort_start, cohort_end)
    @patients.where(recorded_at: cohort_start..cohort_end)
  end

  def followed_up(registered_patients, report_start, report_end)
    registered_patients.select(%(
      patients.*,
      newest_bps.recorded_at as bp_recorded_at,
      newest_bps.systolic as bp_systolic,
      newest_bps.diastolic as bp_diastolic
    )).joins(%(
      INNER JOIN (
        SELECT DISTINCT ON (patient_id) *
        FROM blood_pressures
        WHERE recorded_at >= '#{report_start}'
        AND recorded_at <= '#{report_end}'
        AND deleted_at IS NULL
        ORDER BY patient_id, recorded_at DESC
      ) as newest_bps
      ON newest_bps.patient_id = patients.id
    ))
  end

  def controlled(patients)
    patients.where("newest_bps.systolic < 140 AND newest_bps.diastolic < 90")
  end
end
