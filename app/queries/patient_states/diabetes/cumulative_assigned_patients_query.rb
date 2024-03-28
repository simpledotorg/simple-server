class PatientStates::Diabetes::CumulativeAssignedPatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    Reports::PatientState
      .where(
        assigned_facility_id: region.facility_ids,
        month_date: period
      )
      .where(diabetes: "yes")
      .where.not(htn_care_state: "dead")
  end
end
