class ControlRateQuery
  def controlled(region, period)
    if period.quarter?
      bp_quarterly_query(region, period).under_control
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(
        bp_monthly_query(region, period), "latest_blood_pressures_per_patient_per_months"
      ).under_control
    end
  end

  def uncontrolled(region, period)
    if period.quarter?
      bp_quarterly_query(region, period).hypertensive
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(
        bp_monthly_query(region, period), "latest_blood_pressures_per_patient_per_months"
      ).hypertensive
    end
  end

  private

  def bp_quarterly_query(region, period)
    quarter = period.value
    cohort_quarter = quarter.previous_quarter
    # TODO: fix timezone issue
    LatestBloodPressuresPerPatientPerQuarter
      .for_reports
      .where(assigned_facility_id: region.facilities)
      .where(year: quarter.year, quarter: quarter.number)
      .where("patient_recorded_at >= ? and patient_recorded_at <= ?", cohort_quarter.beginning_of_quarter, cohort_quarter.end_of_quarter)
      .order("patient_id, bp_recorded_at DESC, bp_id")
  end

  def bp_monthly_query(region, period)
    control_range = period.blood_pressure_control_range
    # We need to avoid the default scope to avoid ambiguous column errors, hence the `with_discarded`
    # Note that the deleted_at scoping piece is applied when the SQL view is created, so we don't need to worry about it here
    # TODO: fix timezone issue
    LatestBloodPressuresPerPatientPerMonth
      .with_discarded
      .for_reports
      .select("distinct on (latest_blood_pressures_per_patient_per_months.patient_id) *")
      .where(assigned_facility_id: region.facilities)
      .where("patient_recorded_at <= ?", period.adjusted_period.end)
      .where("bp_recorded_at >= ? and bp_recorded_at <= ?", control_range.begin, control_range.end)
      .order("latest_blood_pressures_per_patient_per_months.patient_id, bp_recorded_at DESC, bp_id")
  end
end
