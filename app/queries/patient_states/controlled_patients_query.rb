class PatientStates::ControlledPatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::AdjustedAssignedPatientsQuery.new(region, period)
      .call
      .where(htn_care_state: "under_care", htn_treatment_outcome_in_last_3_months: "controlled")
  end
end
