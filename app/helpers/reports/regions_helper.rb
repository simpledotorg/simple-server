module Reports::RegionsHelper
  def reports_region_facility_details_path(facility, options = {})
    options.with_defaults! report_scope: "facility"
    reports_region_details_path(facility, options)
  end

  def reports_region_facility_path(facility, options = {})
    options.with_defaults! report_scope: "facility"
    reports_region_path(facility, options)
  end

  def reports_region_district_path(district, options = {})
    options.with_defaults! report_scope: "district"
    reports_region_path(district, options)
  end

  def percentage_or_na(value, options)
    return "N/A" if value.blank?
    number_to_percentage(value, options)
  end

  def cohort_report_type(period)
    "#{period.type.to_s.humanize}ly report"
  end
end
