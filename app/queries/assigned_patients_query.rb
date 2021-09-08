class AssignedPatientsQuery
  # Returns hypertensive assigned counts for a region
  def count(region, period_type)
    region
      .assigned_patients
      .for_reports
      .group_by_period(period_type, :recorded_at, {format: Period.formatter(period_type)})
      .count
  end
end
