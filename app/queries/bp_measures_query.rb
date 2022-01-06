# frozen_string_literal: true

class BPMeasuresQuery
  def count(region, period_type, diagnosis: :hypertension, group_by: nil)
    query = BloodPressure
      .joins(:patient).merge(Patient.with_hypertension)
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
end
