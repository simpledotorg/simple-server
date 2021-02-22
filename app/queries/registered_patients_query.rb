class RegisteredPatientsQuery
  def count(region, period_type)
    formatter = lambda { |v| period_type == :quarter ? Period.quarter(v) : Period.month(v) }
    region.registered_patients
      .with_hypertension
      .group_by_period(period_type, :recorded_at, {format: formatter})
      .count
  end
end
