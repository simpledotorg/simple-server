class ControlRateQueryV2
  def controlled(region)
    Reports::PatientStatesPerMonth
      .where(patient_assigned_facility_id: region.facilities)
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
      .where(htn_treatment_outcome_in_last_3_months: :controlled)
  end

  def controlled_counts(region)
    controlled(region).group_by_period(:month, :month_date, format: Period.formatter(:month)).count
  end

  def uncontrolled(region)
    Reports::PatientStatesPerMonth
      .where(patient_assigned_facility_id: region.facilities)
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
      .where(htn_treatment_outcome_in_last_3_months: :uncontrolled)
  end

  def uncontrolled_counts(region)
    uncontrolled(region).group_by_period(:month, :month_date, format: Period.formatter(:month)).count
  end
end
