class PatientStates::MonthlyRegistrationsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    Reports::PatientState
      .where(
        registration_facility_id: region.facility_ids,
        month_date: period
      )
      .where("months_since_registration = ?", 0)
  end
end
