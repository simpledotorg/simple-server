class ControlRateQueryV2
  def controlled(region)
    ReportingPipeline::PatientStatesPerMonth
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where(patient_assigned_facility_id: region.facilities)
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
      .where(htn_treatment_outcome_in_last_3_months: :controlled)
  end

  def controlled_counts(region, range: nil)
    time_range = (range.begin.start_time..range.end.end_time)
    controlled(region).group_by_period(:month, :month_date, range: time_range, format: Period.formatter(:month)).count
  end

  def uncontrolled(region)
    ReportingPipeline::PatientStatesPerMonth
      .where(patient_assigned_facility_id: region.facilities)
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
      .where(htn_treatment_outcome_in_last_3_months: :uncontrolled)
  end

  def uncontrolled_counts(region, range: nil)
    time_range = (range.begin.start_time..range.end.end_time)
    uncontrolled(region).group_by_period(:month, :month_date, range: time_range, format: Period.formatter(:month)).count
  end
end
