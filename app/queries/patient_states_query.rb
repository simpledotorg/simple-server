class PatientStatesQuery
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def cumulative_assigned_patients
    Reports::PatientState.where(assigned_facility_id: region.facility_ids)
  end
end
