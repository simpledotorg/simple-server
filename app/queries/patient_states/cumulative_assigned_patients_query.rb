class PatientStates::CumulativeAssignedPatientsQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def call
    Reports::PatientState.where(
      assigned_facility_id: region.facility_ids,
      month_date: period
    )
  end
end
