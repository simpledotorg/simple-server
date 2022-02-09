class RegisteredPatientsQuery
  # Daily counts are different enough to warrant their own method:
  #  * we don't use Periods at all
  #  * we want to enforce `last`, as typically you would want at most the last 30 days of daily registrations
  #  * we need to take into account diagnosis here (for progress tab usage)
  #
  # Returns a count of registered patients over the past last days
  def count_daily(region, diagnosis: :hypertension, last:)
    scope = case diagnosis
    when :all then region.registered_patients
    when :hypertension then region.registered_hypertension_patients
    when :diabetes then region.registered_diabetes_patients
    else raise ArgumentError, "unknown diagnosis #{diagnosis}"
    end
    scope.group_by_period(:day, :recorded_at, last: last).count
  end

  def count(region, period_type, group_by: nil)
    query = region.registered_patients
      .with_hypertension
      .group_by_period(period_type, :recorded_at, {format: Period.formatter(period_type)})

    if group_by.present?
      results = query.group(group_by).count
      sum_groups_per_period(results)
    else
      query.count
    end
  end

  private

  def sum_groups_per_period(result)
    result.each_with_object({}) { |(key, count), hsh|
      period, field_id = *key
      hsh[period] ||= {}
      hsh[period][field_id] = count
    }
  end
end
