class ControlRateQuery
  def controlled(region, period, with_exclusions: false)
    if period.quarter?
      bp_quarterly_query(region, period, with_exclusions).under_control
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(
        bp_monthly_query(region, period, with_exclusions), "latest_blood_pressures_per_patient_per_months"
      ).under_control
    end
  end

  def uncontrolled(region, period, with_exclusions: false)
    if period.quarter?
      bp_quarterly_query(region, period, with_exclusions).hypertensive
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(
        bp_monthly_query(region, period, with_exclusions), "latest_blood_pressures_per_patient_per_months"
      ).hypertensive
    end
  end

  private

  def bp_quarterly_query(region, period, with_exclusions)
    quarter = period.value
    cohort_quarter = quarter.previous_quarter
    LatestBloodPressuresPerPatientPerQuarter
      .for_reports(with_exclusions: with_exclusions)
      .where(assigned_facility_id: region.facilities)
      .where(year: quarter.year, quarter: quarter.number)
      .where("patient_recorded_at >= ? and patient_recorded_at <= ?", cohort_quarter.beginning_of_quarter, cohort_quarter.end_of_quarter)
      .order("patient_id, bp_recorded_at DESC, bp_id")
  end

  def bp_monthly_query(region, period, with_exclusions)
    control_range = period.blood_pressure_control_range
    # We need to avoid the default scope to avoid ambiguous column errors, hence the `with_discarded`
    # Note that the deleted_at scoping piece is applied when the SQL view is created, so we don't need to worry about it here
    LatestBloodPressuresPerPatientPerMonth
      .with_discarded
      .for_reports(with_exclusions: with_exclusions)
      .select("distinct on (latest_blood_pressures_per_patient_per_months.patient_id) *")
      .where(assigned_facility_id: region.facilities)
      .where("patient_recorded_at < ?", control_range.begin) # TODO this doesn't seem right -- revisit this exclusion
      .where("bp_recorded_at > ? and bp_recorded_at <= ?", control_range.begin, control_range.end)
      .order("latest_blood_pressures_per_patient_per_months.patient_id, bp_recorded_at DESC, bp_id")
  end
end
