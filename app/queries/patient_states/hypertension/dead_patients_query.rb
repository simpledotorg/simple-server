class PatientStates::Hypertension::DeadPatientsQuery
  attr_reader :facility_id, :period

  def initialize(facility_id, period)
    @facility_id = facility_id
    @period = period
  end

  def call
    Reports::PatientState
      .where(
        assigned_facility_id: facility_id,
        month_date: period
      )
      .where(htn_care_state: "dead")
  end
end
