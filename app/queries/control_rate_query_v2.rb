class ControlRateQueryV2
  def controlled(region)
    result = Reports::PatientStatesPerMonth
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("months_since_registration >= ?", 3)
      .where(htn_treatment_outcome_in_last_3_months: :controlled)
      .where(patient_assigned_facility_id: region.facilities)
      .group_by_period(:month, :month_date)
      .count
      pp result
      result
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
end
