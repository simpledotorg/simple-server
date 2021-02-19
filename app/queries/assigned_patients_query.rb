class AssignedPatientsQuery
  # Returns ALL assigned counts for a region
  def count(region, period_type, with_exclusions: false)
    formatter = lambda { |v| period_type == :quarter ? Period.quarter(v) : Period.month(v) }

    query = region.assigned_patients
    query = query.for_reports(with_exclusions: with_exclusions) if with_exclusions
    query.group_by_period(period_type, :recorded_at, {format: formatter}).count
  end
end
