module DashboardHelper
  def lighten_if_zero(value)
    value&.positive? ? value : content_tag(:span, value, class: "zero")
  end

  def dash_if_zero(value)
    (value == nil || value == 0) ? "-" : value
  end

  def analytics_date_format(time)
    time.strftime('%Y-%m-%d')
  end

  def range_for_quarter(offset)
    date = Date.today + (3 * offset).months
    { from_time: date.at_beginning_of_quarter,
      to_time: date.at_end_of_quarter }
  end

  def label_for_quarter(range)
    quarter = range[:to_time].month / 3
    year = range[:to_time].year

    "Q#{quarter} #{year}"
  end

  def link_for_range(range, from_time, to_time, label)
    is_active = from_time.to_date == range[:from_time].to_date && to_time.to_date == range[:to_time].to_date
    link_to label,
            url_for(range),
            class: is_active ? 'sub-nav-link  sub-nav-link-active' : 'sub-nav-link'
  end

  def string_for_range(from_time, to_time)
    if from_time.to_date == 90.days.ago.to_date
      t('analytics.last_90_days')
    else
      label_for_quarter({ from_time: from_time, to_time: to_time })
    end
  end

  def perform_facility_group_caching(from_time_string, to_time_string)
    FacilityGroup.all.each do |facility_group|
      WarmUpFacilityGroupAnalyticsCacheJob.perform_later(
        facility_group,
        from_time_string,
        to_time_string)

      facility_group.facilities.each do |facility|
        WarmUpFacilityAnalyticsCacheJob.perform_later(
          facility, from_time_string, to_time_string)
      end
    end
  end

  def perform_districts_caching(from_time_string, to_time_string)
    Organization.all.each do |organization|
      district_facilities_map = organization.facilities.group_by(&:district)

      district_facilities_map.each do |name, facilities|
        district = OrganizationDistrict.new(name, organization, facilities)

        WarmUpDistrictAnalyticsCacheJob.perform_later(
          district,
          from_time_string,
          to_time_string)

        district.facilities.each do |facility|
          WarmUpFacilityAnalyticsCacheJob.perform_later(
            facility, from_time_string, to_time_string)
        end
      end
    end
  end
end
