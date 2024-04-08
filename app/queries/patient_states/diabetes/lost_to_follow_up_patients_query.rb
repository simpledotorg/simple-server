class PatientStates::Diabetes::LostToFollowUpPatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::Diabetes::CumulativeAssignedPatientsQuery.new(region, period)
      .call
      .where(htn_care_state: "lost_to_follow_up")
  end
end
