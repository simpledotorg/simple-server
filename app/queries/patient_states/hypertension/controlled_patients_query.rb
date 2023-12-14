class PatientStates::Hypertension::ControlledPatientsQuery
  attr_reader :facility_id, :period

  def initialize(facility_id, period)
    @facility_id = facility_id
    @period = period
  end

  def call
    PatientStates::Hypertension::AdjustedAssignedPatientsQuery.new(facility_id, period)
      .call
      .where(htn_care_state: "under_care", htn_treatment_outcome_in_last_3_months: "controlled")
  end
end
