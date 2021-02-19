class AssignedPatientsQuery
  # Returns ALL assigned counts for a region
  def count(region, type, with_exclusions: false)
    formatter = lambda { |v| type == :quarter ? Period.quarter(v) : Period.month(v) }

    query = region.assigned_patients
    query = query.for_reports(with_exclusions: with_exclusions) if with_exclusions
    query.group_by_period(type.to_s, :recorded_at, {format: formatter}).count
  end
end
