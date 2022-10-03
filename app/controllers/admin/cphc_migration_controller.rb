class Admin::CphcMigrationController < AdminController
  include SearchHelper
  include Pagination

  helper_method :get_migrated_records

  MIGRATING_DISTRICT_SLUGS = ["bikaner", "churu"]
  def index
    authorize { current_admin.power_user? }

    migrating_facility_groups = FacilityGroup.where(slug: MIGRATING_DISTRICT_SLUGS)
    accessible_facilities = current_admin
      .accessible_facilities(:manage)
      .where(facility_group: migrating_facility_groups)
    facility_groups = FacilityGroup.where(
      slug: params[:district_slugs] || MIGRATING_DISTRICT_SLUGS
    )

    facilities = if searching?
      accessible_facilities.search_by_name(search_query)
    elsif params[:unlinked_facilities]
      accessible_facilities
        .where(facility_group: facility_groups)
        .left_outer_joins(:cphc_facility_mappings)
        .where(cphc_facility_mappings: {facility_id: nil})
        .distinct
    elsif params[:error_facilities]
      accessible_facilities
        .where(facility_group: facility_groups)
        .left_outer_joins(:cphc_migration_error_logs)
        .where.not(cphc_migration_error_logs: {facility_id: nil})
        .distinct
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
    CphcFacilityMapping.where(cphc_phc_id: params[:cphc_phc_id])
      .update_all(facility_id: remove_mapping ? nil : params[:facility_id])
    redirect_to admin_cphc_migration_path, notice: "CPHC Facility Mapping Added"
  end

  def migrate_to_cphc
    authorize { current_admin.power_user? }
  end

  def get_migrated_records(klass, facility)
    CphcMigrationAuditLog
      .where(facility: facility, cphc_migratable_type: klass.to_s.camelcase)
      .order(created_at: :desc)
  end
end
