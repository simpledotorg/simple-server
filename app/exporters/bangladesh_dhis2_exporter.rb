class BangladeshDhis2Exporter
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  def data
    {
      cumulative_assigned_patients: cumulative_assigned_patients_count
    }
  end

  def cumulative_assigned_patients_count
    PatientStates::DisaggregatedPatientCountQuery.disaggregate_by(
      PatientStates::CumulativeAssignedPatientsQuery.new(region, period),
      groupings
    )
  end

  def groupings
    :gender
  end
end
