class PatientStates::Diabetes::MissedVisitsPatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::Diabetes::AdjustedAssignedPatientsQuery.new(region, period)
      .call
      .where(htn_care_state: "under_care")
      .where(diabetes_treatment_outcome_in_last_3_months: "missed_visit")
  end
end
