class AssignedPatientsQuery
  # Returns hypertensive assigned counts for a region
  def count(region, period_type)
    formatter = lambda { |v| period_type == :quarter ? Period.quarter(v) : Period.month(v) }

    region
      .assigned_patients
      .for_reports
      .group_by_period(period_type, :recorded_at, {format: formatter})
      .count
  end
end
