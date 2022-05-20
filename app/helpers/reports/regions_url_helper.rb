module Reports::RegionsUrlHelper
  def reports_region_facility_path(facility, options = {})
    options.with_defaults! report_scope: :facility
    reports_region_path(facility, options)
  end

  def reports_region_district_path(district, options = {})
    options.with_defaults! report_scope: :district
    reports_region_path(district, options)
  end
end
