# frozen_string_literal: true

class RegisteredPatientsQuery
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
