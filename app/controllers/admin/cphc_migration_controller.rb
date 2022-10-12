class Admin::CphcMigrationController < AdminController
  include SearchHelper
  include Pagination

  before_action :render_only_in_india
  helper_method :get_migrated_records

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
  end

  def update_cphc_mapping
    authorize { current_admin.power_user? }
    remove_mapping = params[:remove_mapping]
    CphcFacilityMapping.where(cphc_phc_id: params[:cphc_phc_id])
      .update_all(facility_id: remove_mapping ? nil : params[:facility_id])
    redirect_to request.referrer, notice: "CPHC Facility Mapping Added"
  end

  def migrate_to_cphc
    authorize { current_admin.power_user? }
    set_migratable_patients

    @patients.each do |patient|
      CphcMigrationJob.perform_at(OneOff::CphcEnrollment.next_migration_time(Time.now), patient.id)
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
    end

    if region.present?
      @patients = region
        .assigned_patients
        .left_outer_joins(:cphc_migration_audit_log)
        .where(cphc_migration_audit_logs: {id: nil})
      @migratable_name = region.name
    else
      patient = Patient.find(params[:patient_id])
      @patients = [patient]
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
