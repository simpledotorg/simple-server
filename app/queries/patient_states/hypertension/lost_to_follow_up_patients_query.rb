class PatientStates::Hypertension::LostToFollowUpPatientsQuery
  attr_reader :facility_id, :period

  def initialize(facility_id, period)
    @facility_id = facility_id
    @period = period
  end

  def call
    PatientStates::Hypertension::CumulativeAssignedPatientsQuery.new(facility_id, period)
      .call
      .where(htn_care_state: "lost_to_follow_up")
  end
end
