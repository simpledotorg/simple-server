class PatientStates::Diabetes::MonthlyRegistrationsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::Diabetes::CumulativeRegistrationsQuery
      .new(region, period)
      .call
      .where(months_since_registration: 0)
  end
end
