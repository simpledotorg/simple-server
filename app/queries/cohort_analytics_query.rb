class CohortAnalyticsQuery
  include QuarterHelper

  def initialize(patients)
    @patients = patients
  end

  def patient_counts(year:, quarter:, quarters_previous: 1)
    report_start = quarter_start(year, quarter)
    report_end   = quarter_end(year, quarter)

    cohort_start = report_start - (quarters_previous * 3).months
    cohort_end   = report_end   - (quarters_previous * 3).months

    registered_patients = registered(cohort_start, cohort_end)
    followed_up_patients = followed_up(registered_patients, report_start, report_end)
    controlled_patients = controlled(followed_up_patients)
    uncontrolled_patients = followed_up_patients - controlled_patients

    {
      registered: registered_patients.size,
      followed_up: followed_up_patients.size,
      defaulted: registered_patients.size - followed_up_patients.size,
      controlled: controlled_patients.size,
      uncontrolled: uncontrolled_patients.size
    }
  end

  def registered(cohort_start, cohort_end)
    @patients.where(recorded_at: cohort_start..cohort_end)
  end

  def followed_up(registered_patients, report_start, report_end)
    registered_patients.select(%Q(
      patients.*,
      newest_bps.device_created_at as bp_device_created_at,
      newest_bps.systolic as bp_systolic,
      newest_bps.diastolic as bp_diastolic
    )).joins(%Q(
      INNER JOIN (
        SELECT DISTINCT ON (patient_id) *
        FROM blood_pressures
        WHERE device_created_at >= '#{report_start}'
        AND device_created_at <= '#{report_end}'
        ORDER BY patient_id, device_created_at DESC
      ) as newest_bps
      ON newest_bps.patient_id = patients.id
    ))
  end

  def controlled(patients)
    patients.select { |p| p.bp_systolic < 140 && p.bp_diastolic < 90 }
  end
end
