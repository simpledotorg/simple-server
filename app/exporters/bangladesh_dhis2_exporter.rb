class BangladeshDhis2Exporter
  attr_reader :region, :period

  def initialize(region, period)
    @region = region
    @period = period
  end

  BUCKETS = (15..75).step(5)

  def data
    {
      cumulative_assigned_patients: disaggregated_counts(PatientStates::CumulativeAssignedPatientsQuery.new(region, period)),
      controlled_patients: disaggregated_counts(PatientStates::ControlledPatientsQuery.new(region, period)),
      uncontrolled_patients: disaggregated_counts(PatientStates::UncontrolledPatientsQuery.new(region, period))
    }
  end

  def disaggregated_counts(query)
    PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
      BUCKETS,
      PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(
        query.call
      )
    ).count
  end
end
