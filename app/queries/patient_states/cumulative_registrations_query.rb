class PatientStates::CumulativeRegistrationsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::CumulativeAssignedPatientsQuery.new(region, period)
      .call
  end
end
