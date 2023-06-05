class OverduePatientsQuery
  def count_patients_called(region, period_type, group_by: nil)
    query = Reports::OverduePatient
            .group_by_period(period_type, :month_date, { format: Period.formatter(period_type) })
            .where(has_called: 'yes')
            .where('assigned_facility_region_id in (?)', region.facility_regions.pluck(:id))
    if group_by.present?
      results = query.group(group_by).count
      sum_groups_by_period(results)
    else
      query.count
    end
  end

  private

  def sum_groups_by_period(result)
    result.each_with_object({}) do |(key, count), hsh|
      period, field_id = *key
      hsh[period] ||= {}
      hsh[period][field_id] = count
    end
  end
end
