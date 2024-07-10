class PatientStates::Hypertension::RegistrationsUnderCareQuery
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
      .where(hypertension: "yes")
      .where(htn_care_state: "under_care")
  end
end
