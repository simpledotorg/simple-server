class PatientStates::Diabetes::BsBelow200PatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::Diabetes::AdjustedAssignedPatientsQuery.new(region, period)
      .call
      .where(htn_care_state: "under_care", diabetes_treatment_outcome_in_last_3_months: "bs_below_200")
  end
end
