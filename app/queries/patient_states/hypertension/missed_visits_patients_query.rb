class PatientStates::Hypertension::MissedVisitsPatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::Hypertension::AdjustedAssignedPatientsQuery.new(region, period)
      .call
      .where(htn_care_state: "under_care")
      .where(htn_treatment_outcome_in_last_3_months: "missed_visit")
  end
end
