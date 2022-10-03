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

    @unmapped_cphc_facilites = CphcFacilityMapping.where(facility: nil)
  end

  def update_cphc_mapping
    authorize { current_admin.power_user? }
    remove_mapping = params[:remove_mapping]
    CphcFacilityMapping.find_by(
      params.permit(
        :cphc_state_id,
        :cphc_district_id,
        :cphc_taluka_id,
        :cphc_phc_id,
        :cphc_subcenter_id,
        :cphc_village_id
      )
    ).update!(facility_id: remove_mapping ? nil : params[:facility_id])
    redirect_to admin_cphc_migration_path, notice: "CPHC Facility Mapping Added"
  end
end
