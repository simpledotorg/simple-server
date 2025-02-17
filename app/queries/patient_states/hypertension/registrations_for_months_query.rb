class PatientStates::Hypertension::RegistrationsForMonthsQuery
  attr_reader :region, :period, :months_registration

  def initialize(region, period, months_registration)
    @region = region
    @period = period
    @months_registration = months_registration
  end

  def call
    Reports::PatientState
      .where(
        registration_facility_id: region.facility_ids,
        month_date: period
      )
      .where(hypertension: "yes")
      .where(months_since_registration: months_registration)
  end
end
