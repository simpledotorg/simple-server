class CohortAnalyticsQuery
  def initialize(patients, year, quarter, quarters_previous=2)
    @patients = patients
    @year = year
    @quarter = quarter
    @quarters_previous = quarters_previous

    @cohort_start = quarter_start(@year, @quarter) - (@quarters_previous * 3).months
    @cohort_end   = quarter_end(@year, @quarter)
  end

  def patient_counts
    cohort_start = quarter_start(year, quarter)
    cohort_end   = quarter_end(year, quarter)
  end

  def registered(year, cohort_start, cohort_end)
    cohort_start = @from_time - COHORT_MONTHS_PREVIOUS.months
    cohort_end = @to_time - COHORT_MONTHS_PREVIOUS.months

    @patients.select(%Q(
      patients.*,
      oldest_bps.device_created_at as bp_device_created_at,
      oldest_bps.facility_id as bp_facility_id,
      oldest_bps.systolic as bp_systolic,
      oldest_bps.diastolic as bp_diastolic
    )).joins(%Q(
      INNER JOIN (
        SELECT DISTINCT ON (patient_id) *
        FROM blood_pressures
        ORDER BY patient_id, device_created_at ASC
      ) as oldest_bps
      ON oldest_bps.patient_id = patients.id
    )).where(
      "oldest_bps.device_created_at" => cohort_start..cohort_end,
      "oldest_bps.facility_id" => @facility
    )
  end

  def visited(patients, quarter_start, quarter_end)
    patients.select(%Q(
      patients.*,
      newest_bps.device_created_at as bp_device_created_at,
      newest_bps.systolic as bp_systolic,
      newest_bps.diastolic as bp_diastolic
    )).joins(%Q(
      INNER JOIN (
        SELECT DISTINCT ON (patient_id) *
        FROM blood_pressures
        WHERE device_created_at >= '#{quarter_start}'
        AND device_created_at <= '#{quarter_end}'
        ORDER BY patient_id, device_created_at DESC
      ) as newest_bps
      ON newest_bps.patient_id = patients.id
    ))
  end

  def controlled(patients)
    patients.select { |p| p.bp_systolic < 140 && p.bp_diastolic < 90 }
  end

  def uncontrolled(patients)
    patients.select { |p| p.bp_systolic >= 140 || p.bp_diastolic >= 90 }
  end

  private

  def quarter_datetime(year, quarter)
    quarter_month = ((quarter - 1) * 3) + 1
    DateTime.new(year, quarter_month, 1)
  end

  def quarter_start(year, quarter)
    quarter_datetime(year, quarter).beginning_of_quarter
  end

  def quarter_end(year, quarter)
    quarter_datetime(year, quarter).end_of_quarter
  end
end
