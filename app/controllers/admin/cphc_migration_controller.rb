class Admin::CphcMigrationController < AdminController
  include SearchHelper
  include Pagination

  before_action :render_only_in_india
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
      facility_ids = accessible_facilities
        .where(facility_group: facility_groups)
        .joins("left outer join cphc_migration_error_logs on cphc_migration_error_logs.facility_id = facilities.id")
        .joins("inner join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
        .distinct(:facility_id)

      accessible_facilities.where(id: facility_ids)
    else
      accessible_facilities
    end
    facility_groups = FacilityGroup.where(facilities: facilities)

    @organizations = Organization.where(facility_groups: facility_groups)
    @facility_groups = facility_groups.group_by(&:organization)
    @facilities = facilities.group_by(&:facility_group)

    @unmapped_cphc_facilites = CphcFacilityMapping.where(facility: nil)
    set_cphc_mappings(facilities)
    set_facility_results(facilities)
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
    set_migratable_patients
    auth_token = ENV["CPHC_AUTH_TOKEN"]

    auth_manager = OneOff::CphcEnrollment::AuthManager.new(auth_token: auth_token)
    @patients.each do |patient|
      CphcMigrationJob.perform_at(
        OneOff::CphcEnrollment.next_migration_time(Time.now),
        patient.id,
        JSON.dump(auth_manager.user)
      )
    end
    redirect_to admin_cphc_migration_path, notice: "Migration triggered for #{@migratable_name}"
  end

  def get_migrated_records(klass, region)
    facilities = if region.is_a? Facility
      [region]
    else
      region.facilities
    end
    CphcMigrationAuditLog
      .where(facility: facilities, cphc_migratable_type: klass.to_s.camelcase)
      .order(created_at: :desc)
  end

  def render_only_in_india
    fail_request(:unauthorized, "only allowed in India") unless CountryConfig.current_country?("India")
  end

  private

  def set_migratable_patients
    region = if params[:facility_group_id].present?
               FacilityGroup.find(params[:facility_group_id])
             elsif params[:facility_id].present?
               Facility.find(params[:facility_id])
             else
               nil
             end

    if region.present?
      @patients = region
                    .assigned_patients
                    .left_outer_joins(:cphc_migration_audit_log)
                    .where(cphc_migration_audit_logs: { id: nil })
      @migratable_name = region.name
    else
      @patients = [Patient.find(params[:patient_id])]
      @migratable_name = patient.full_name
    end
  end

  def set_cphc_mappings(facilities)
    @mappings = CphcFacilityMapping.where(facility_id: facilities).group_by(&:facility_id)
  end

  def set_facility_results(facilities)
    patients = Patient.where(assigned_facility_id: facilities)
    migratables = %w[Patient Encounter BloodPressure BloodSugar PrescriptionDrug Appointment]

    @facility_results = {
      total: {
        patients: patients.group(:assigned_facility_id).count,
        encounters: Encounter.joins(:patient).where(patient_id: patients).group("patients.assigned_facility_id").count,
        blood_pressures: BloodPressure.joins(:patient).where(patient_id: patients).group("patients.assigned_facility_id").count,
        blood_sugars: BloodSugar.joins(:patient).where(patient_id: patients).group("patients.assigned_facility_id").count,
        prescription_drugs: PrescriptionDrug.joins(:patient).where(patient_id: patients).group("patients.assigned_facility_id").count,
        appointments: Appointment.joins(:patient).where(patient_id: patients).group("patients.assigned_facility_id").count
      },
      migrated:
        CphcMigrationAuditLog
          .where(facility_id: facilities, cphc_migratable_type: migratables)
          .group(:cphc_migratable_type, :facility_id)
          .count,
      errors:
        CphcMigrationErrorLog
          .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
          .where("cphc_migration_audit_logs.id is null")
          .group_by(&:facility_id)
    }
  end
end
