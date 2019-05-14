class ControlRateQuery
  attr_reader :patients

  COHORT_DELTA = 6.months

  def initialize(patients:)
    @patients = patients
  end

  def for_period(from_time:, to_time:)
    registered_patients = registered(from_time, to_time)
    visited_patients = visited(registered_patients, from_time, to_time)
    controlled_patients = controlled(visited_patients)
    uncontrolled_patients = visited_patients - controlled_patients

    numerator = controlled_patients.size
    denominator = registered_patients.size
    control_rate = denominator == 0 ? 0 : (numerator.to_f / denominator.to_f * 100).round

    {
      control_rate: control_rate,
      patients_under_control_in_period: numerator,
      hypertensive_patients_in_cohort: denominator,
    }
  end

  def rate_per_month(number_of_months, before_time: Date.today)
    control_rate_per_month = []
    number_of_months.times do |n|
      to_time = (before_time - n.months).at_end_of_month
      from_time = to_time.at_beginning_of_month
      control_rate_per_month << [from_time.to_date, for_period(from_time: from_time, to_time: to_time)[:control_rate] || 0]
    end
    control_rate_per_month.sort.to_h
  end

  private

  def registered(from_time, to_time)
    cohort_start = from_time - COHORT_DELTA
    cohort_end = to_time - COHORT_DELTA

    patients.select(:id).joins(%Q(
      INNER JOIN (
        SELECT DISTINCT ON (patient_id) *
        FROM blood_pressures
        ORDER BY patient_id, device_created_at ASC
      ) as oldest_bps
      ON oldest_bps.patient_id = patients.id
    )).where(
      "oldest_bps.device_created_at" => cohort_start..cohort_end,
    )
  end

  def visited(registered_patients, from_time, to_time)
    registered_patients.select(%Q(
      patients.id,
      newest_bps.device_created_at as bp_device_created_at,
      newest_bps.systolic as bp_systolic,
      newest_bps.diastolic as bp_diastolic
    )).joins(%Q(
      INNER JOIN (
        SELECT DISTINCT ON (patient_id) *
        FROM blood_pressures
        WHERE device_created_at >= '#{from_time}'
        AND device_created_at <= '#{to_time}'
        ORDER BY patient_id, device_created_at DESC
      ) as newest_bps
      ON newest_bps.patient_id = patients.id
    ))
  end

  def controlled(visited_patients)
    visited_patients.select { |p| p.bp_systolic < 140 && p.bp_diastolic < 90 }
  end

  def uncontrolled(visited_patients)
    visited_patients.select { |p| p.bp_systolic >= 140 || p.bp_diastolic >= 90 }
  end
end
