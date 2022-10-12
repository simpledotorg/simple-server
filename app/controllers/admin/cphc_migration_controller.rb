class Admin::CphcMigrationController < AdminController
  include SearchHelper
  include Pagination

  before_action :render_only_in_india
  helper_method :get_migrated_records
  helper_method :migratable_patients
  helper_method :unmapped_facilities
  helper_method :error_facilities

  def index
    authorize { current_admin.power_user? }

    facility_mappings = CphcFacilityMapping.all.select(:facility_id, :district_name)
    mapped_facilities = Facility.where(id: facility_mappings.pluck(:facility_id).uniq)
    facility_group_ids = mapped_facilities.pluck(:facility_group_id).uniq

    facility_groups = current_admin.accessible_facility_groups(:manage)
    @organizations = Organization.where(facility_groups: facility_groups)
    @facility_groups = facility_groups.group_by(&:organization)

    @districts_with_mappings = FacilityGroup
      .where(id: facility_group_ids)
      .group_by(&:organization)

    @districts_without_mappings = FacilityGroup
      .where
      .not(id: facility_group_ids)
      .group_by(&:organization)
  end

  def district
    authorize { current_admin.power_user? }
    @facility_group = FacilityGroup.find_by(slug: params[:district_slug])

    @facilities = if searching?
      @facility_group.facilities.search_by_name(search_query)
    else
      @facility_group.facilities
    end

    facilities = @facility_group.facilities
    facility_mappings = CphcFacilityMapping.where(facility_id: facilities)

    if params[:unlinked_facilities]
      @facilities = facilities
        .left_outer_joins(:cphc_facility_mappings)
        .where(cphc_facility_mappings: {facility_id: nil})
        .distinct
    end

    if params[:error_facilities]
      facility_ids = facilities
        .joins("inner join cphc_migration_error_logs on cphc_migration_error_logs.facility_id = facilities.id")
        .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
        .where("cphc_migration_audit_logs.id is null")
        .distinct(:facility_id)

      @facilities = facilities.where(id: facility_ids)
    end

    @total_unmapped_facilities_count = unmapped_facilities(@facility_group).count
    @total_error_facilities_count = @facility_group
      .facilities
      .joins(:cphc_migration_error_logs)
      .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
      .where("cphc_migration_audit_logs.id is null")
      .distinct(:facility_id)
      .count

    @mappings = facility_mappings.group_by(&:facility_id)

    @unmapped_cphc_facilities = unmapped_facilities(@facility_group)

    set_facility_results(@facilities)
  end

  def update_cphc_mapping
    authorize { current_admin.power_user? }

    facility = Facility.find_by!(slug: params.require(:facility_slug))
    if params[:unlink]
      facility.cphc_facility_mappings.update_all(facility_id: nil)
    else
      CphcFacilityMapping.where(cphc_phc_id: params[:cphc_phc_id])
        .update_all(facility_id: facility.id)
    end

    redirect_to request.referrer, notice: "CPHC Facility Mapping Added"
  end

  def migrate_to_cphc
    authorize { current_admin.power_user? }
    if params[:patient_id]
      @migratable_patients = Patient.where(id: params[:patient_id])
      @migratable_name = patient.full_name
    else
      region = Facility.find_by(slug: params[:facility_slug]) ||
        FacilityGroup.find_by(slug: params[:district_slug])
      @migratable_name = migratable_patients(region)
      @migratable_name = region.name
    end

    @migratable_patients.each do |patient|
      CphcMigrationJob.perform_at(OneOff::CphcEnrollment.next_migration_time(Time.now), patient.id)
    end

    redirect_to request.referrer, notice: "Migration triggered for #{@migratable_name}"
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

  def migratable_patients(region)
    region.assigned_patients
      .left_outer_joins(:cphc_migration_audit_log)
      .where(cphc_migration_audit_logs: {id: nil})
  end

  def unmapped_facilities(facility_group)
    facility_group.facilities
      .left_outer_joins(:cphc_facility_mappings)
      .where({cphc_facility_mappings: {id: nil}})
  end

  def error_facilities(facility_group)
    facility_group
      .facilities
      .joins(:cphc_migration_error_logs)
      .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
      .where("cphc_migration_audit_logs.id is null")
      .distinct(:facility_id)
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
