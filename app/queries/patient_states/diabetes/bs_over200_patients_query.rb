class PatientStates::Diabetes::BsOver200PatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::Diabetes::AdjustedAssignedPatientsQuery.new(region, period)
      .call
      .where(htn_care_state: "under_care", diabetes_treatment_outcome_in_last_3_months: ["bs_200_to_300", "bs_over_300"])
  end
end
