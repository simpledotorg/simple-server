class RegisteredPatientsQuery
  def count(region, period_type, group_by: nil)
    formatter = lambda { |v| period_type == :quarter ? Period.quarter(v) : Period.month(v) }
    query = region.registered_patients
      .with_hypertension
      .group_by_period(period_type, :recorded_at, {format: formatter})

    if group_by
      group_by(query, group_by)
    else
      query.count
    end
  end

  # Add the additonal grouping, and then collect the counts at the per period level
  def group_by(query, group_by)
    query = query.group(group_by)
    query.count.each_with_object({}) { |(key, count), hsh|
      period, user_id = *key
      hsh[period] ||= {}
      hsh[period][user_id] = count
    }
  end
end
