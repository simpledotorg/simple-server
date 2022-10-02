class Admin::CphcMigrationController < AdminController
  include SearchHelper
  include Pagination

  MIGRATING_DISTRICT_SLUGS = ["bikaner", "churu"]
  def index
    authorize { current_admin.power_user? }

    migrating_facility_groups = FacilityGroup.where(slug: MIGRATING_DISTRICT_SLUGS)
    accessible_facilities = current_admin
      .accessible_facilities(:manage)
      .where(facility_group: migrating_facility_groups)

    facilities = if searching?
      accessible_facilities.search_by_name(search_query)
    else
      accessible_facilities
    end
    facility_groups = FacilityGroup.where(facilities: facilities)

    @organizations = Organization.where(facility_groups: facility_groups)
    @facility_groups = facility_groups.group_by(&:organization)
    @facilities = facilities.group_by(&:facility_group)
  end
end
