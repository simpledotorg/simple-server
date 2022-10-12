class RegisteredPatientsQuery
  def count(region, period_type, group_by: nil, diagnosis: :hypertension)
    query = registered_patients_with_diagnosis(region, diagnosis)
      .group_by_period(period_type, :recorded_at, {format: Period.formatter(period_type)})

    if group_by.present?
      results = query.group(group_by).count
      sum_groups_per_period(results)
    else
      query.count
    end
  end

  private

  def registered_patients_with_diagnosis(region, diagnosis)
    case diagnosis
    when :all then region.registered_patients
    when :hypertension then region.registered_hypertension_patients
    when :diabetes then region.registered_diabetes_patients
    else raise ArgumentError, "unknown diagnosis #{diagnosis}"
    end
  end

  def sum_groups_per_period(result)
    result.each_with_object({}) { |(key, count), hsh|
      period, field_id = *key
      hsh[period] ||= {}
      hsh[period][field_id] = count
    }
  end
end
