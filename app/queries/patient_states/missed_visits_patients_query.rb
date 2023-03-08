class PatientStates::MissedVisitsPatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::CumulativeAssignedPatientsQuery.new(region, period)
      .excluding_recent_registrations
      .where(htn_treatment_outcome_in_last_3_months: "missed_visit")
  end
end
