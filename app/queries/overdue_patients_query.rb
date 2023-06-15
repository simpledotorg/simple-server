class OverduePatientsQuery
  FILTERS_CONTACTABLE_OVERDUE_PATIENTS_CALLED = {has_called: "yes", removed_from_overdue_list: "no", has_phone: "yes", hypertension: "yes", under_care: "yes"}
  FILTERS_PATIENTS_CALLED = {has_called: "yes", hypertension: "yes", under_care: "yes"}

  def count_patients_called(region, period_type, group_by: nil)
    count_patients(region, period_type, group_by: group_by, filters: FILTERS_PATIENTS_CALLED)
  end

  def count_contactable_patients_called(region, period_type, group_by: nil)
    count_patients(region, period_type, group_by: group_by, filters: FILTERS_CONTACTABLE_OVERDUE_PATIENTS_CALLED)
  end

  def count_patients(region, period_type, group_by: nil, filters: {})
    query = Reports::OverduePatient
      .group_by_period(period_type, :month_date, {format: Period.formatter(period_type)})
      .where(filters)
      .where("assigned_facility_region_id in (?)", region.facility_regions.pluck(:id))
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
