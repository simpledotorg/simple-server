# frozen_string_literal: true

class OverdueCallsQuery
  def count(region, period_type, group_by: nil)
    query = Reports::OverdueCalls
      .group_by_period(period_type, :call_result_created_at, {format: Period.formatter(period_type)})
      .where("appointment_facility_region_id in (?)", region.facility_regions.pluck(:id))
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
