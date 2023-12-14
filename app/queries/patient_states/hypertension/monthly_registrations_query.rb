class PatientStates::Hypertension::MonthlyRegistrationsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    PatientStates::Hypertension::CumulativeRegistrationsQuery
      .new(region, period)
      .call
      .where(months_since_registration: 0)
  end
end
