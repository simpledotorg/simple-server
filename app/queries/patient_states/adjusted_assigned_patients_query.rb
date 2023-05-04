class PatientStates::AdjustedAssignedPatientsQuery
  attr_reader :region, :period
  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::CumulativeAssignedPatientsQuery
      .new(region, period)
      .call
      .where("months_since_registration >= ?", 3)
  end
end
