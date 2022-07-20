class MeasuresQuery
  def count(region, period_type, diagnosis: :hypertension, group_by: nil)
    query = measures_for_diagnosis(diagnosis)
      .group_by_period(period_type, :recorded_at, {format: Period.formatter(period_type)})
      .where(facility: region.facilities)
    if group_by.present?
      results = query.group(group_by).count
      sum_groups_by_period(results)
    else
      query.count
    end
  end

  def sum_groups_by_period(result)
    result.each_with_object({}) { |(key, count), hsh|
      period, field_id = *key
      hsh[period] ||= {}
      hsh[period][field_id] = count
    }
  end

  private

  def measures_for_diagnosis(diagnosis)
    case diagnosis
    when :hypertension
      BloodPressure.joins(:patient).merge(Patient.with_hypertension)
    when :diabetes
      BloodSugar.joins(:patient).merge(Patient.with_diabetes)
    else raise ArgumentError, "unknown diagnosis #{diagnosis}"
    end
  end
end
