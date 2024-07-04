class PatientStates::Diabetes::DeadPatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    Reports::PatientState
      .where(
        assigned_facility_id: region.facility_ids,
        month_date: period,
        diabetes: "yes"
      )
      .where(htn_care_state: "dead")
  end
end
