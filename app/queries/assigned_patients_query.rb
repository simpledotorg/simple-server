class AssignedPatientsQuery
  include Reports::SchemaV2

  def initialize(reporting_schema_v2: false)
    @reporting_schema_v2 = reporting_schema_v2
  end

  # Returns hypertensive assigned counts for a region
  def count(region, period_type)
    if reporting_schema_v2?
      count_v2(region, period_type)
    else
      count_v1(region, period_type)
    end
  end

  def count_v1(region, period_type)
    region
      .assigned_patients
      .for_reports
      .group_by_period(period_type, :recorded_at, {format: Period.formatter(period_type)})
      .count
  end

  def count_v2(region, period_type)
    Reports::PatientStatesPerMonth
        .where(hypertension: "yes")
        .where(patient_assigned_facility_id: region.facilities)
        .group_by_period(:month, :recorded_at, format: Period.formatter(:month))
        .count
  end
end
