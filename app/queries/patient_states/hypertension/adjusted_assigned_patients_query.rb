class PatientStates::Hypertension::AdjustedAssignedPatientsQuery
  attr_reader :facility_id, :period

  def initialize(facility_id, period)
    @facility_id = facility_id
    @period = period
  end

  def call
    PatientStates::Hypertension::CumulativeAssignedPatientsQuery
      .new(facility_id, period)
      .call
      .where("months_since_registration >= ?", 3)
  end
end
