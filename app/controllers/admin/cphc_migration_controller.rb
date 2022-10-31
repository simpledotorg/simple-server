class Admin::CphcMigrationController < AdminController
  include SearchHelper
  include Pagination
  include Reports::Percentage

  before_action :render_only_in_india
  helper_method :get_migrated_records
  helper_method :migratable_patients
  helper_method :unmapped_facilities
  helper_method :error_facilities
  helper_method :migration_summary
  helper_method :region_summary
  helper_method :migratable_region?

  MIGRATABLE_REGIONS = ["state", "district", "block", "facility"]

  def index
    authorize { current_admin.power_user? }

    authorize { current_admin.power_user? }

    @region = Region.root
    @region_summary = region_summary(@region)

    totals = @region_summary.dig(:totals, "Patient")
    migrated = @region_summary.dig(:migrated, "Patient")
    errors = @region_summary.dig(:errors, "Patient")
    @region_progress = {
      migrated: percentage(migrated, totals),
      errors: percentage(errors, totals)
    }

    render "admin/cphc_migration/region"
  end

  def region
    authorize { current_admin.power_user? }

    @region = Region.find_by!(region_type: params.require(:region_type), slug: params.require(:slug))
    @region_summary = region_summary(@region)

    totals = @region_summary.dig(:totals, "Patient")
    migrated = @region_summary.dig(:migrated, "Patient")
    errors = @region_summary.dig(:errors, "Patient")
    @region_progress = {
      migrated: percentage(migrated, totals),
      errors: percentage(errors, totals)
    }

    if MIGRATABLE_REGIONS.include?(@region.child_region_type)
      @child_summary = child_summary(@region)
    end
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

  def update_credentials
    authorize { current_admin.power_user? }

    region = Region.find_by!(region_type: params.require(:region_type), slug: params.require(:slug))
    region.facilities.each do |facility|
      CphcCreateUserJob.perform_async(facility.id)
    end

    redirect_to request.referrer, notice: "Started updating credentials for #{region.region_type} #{region.name}"
  end

  def migrate_region
    authorize { current_admin.power_user? }

    region = Region.find_by!(region_type: params.require(:region_type), slug: params.require(:slug))

    migratable_patients(region).each do |patient|
      CphcMigrationJob.perform_at(OneOff::CphcEnrollment.next_migration_time(Time.now), patient.id)
    end

    redirect_to request.referrer, notice: "Migration triggered for #{region.name}"
  end

  def migrate_to_cphc
    authorize { current_admin.power_user? }
    if params[:patient_id]
      @migratable_patients = Patient.where(id: params[:patient_id])
      @migratable_name = patient.full_name
    else
      region = Facility.find_by(slug: params[:facility_slug]) ||
        FacilityGroup.find_by(slug: params[:district_slug])
      @migratable_patients = migratable_patients(region)
      @migratable_name = region.name
    end

    @migratable_patients.each do |patient|
      CphcMigrationJob.perform_at(OneOff::CphcEnrollment.next_migration_time(Time.now), patient.id)
    end

    redirect_to request.referrer, notice: "Migration triggered for #{@migratable_name}"
  end

  def error_line_list
    authorize { current_admin.power_user? }

    region = Region.find_by!(
      region_type: params.require(:region_type),
      slug: params.require(:region_slug)
    )

    CphcMigrationErrorsDownloadJob.perform_async(
      current_admin.email,
      region.region_type,
      region.slug
    )

    redirect_to request.referrer, notice: "Email will be sent to #{current_admin.email}"
  end

  def cancel_all
    authorize { current_admin.power_user? }

    Sidekiq::Queue.new("cphc_migration").clear
    Sidekiq::ScheduledSet.new
      .select { |job| job.queue == "cphc_migration" }
      .map(&:delete)
  end

  def cancel_region_migration
    authorize { current_admin.power_user? }

    region = Region.find_by!(
      region_type: params.require(:region_type),
      slug: params.require(:slug)
    )
    patients = region.assigned_patients.pluck(:id).to_set

    Sidekiq::Queue.new("cphc_migration")
      .select { |job| patients.include?(job.args.first) }
      .map(&:delete)
    Sidekiq::ScheduledSet.new
      .select { |job| job.queue == "cphc_migration" && patients.include?(job.args.first) }
      .map(&:delete)
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

  private

  def migratable_patients(region)
    region.assigned_patients
      .left_outer_joins(:cphc_migration_audit_log)
      .where(cphc_migration_audit_logs: {id: nil})
  end

  def mapped_facilities(region)
    region.facilities
      .left_outer_joins(:cphc_facility_mappings)
      .where.not({cphc_facility_mappings: {id: nil}})
  end

  def unmapped_facilities(region)
    region.facilities
      .left_outer_joins(:cphc_facility_mappings)
      .where({cphc_facility_mappings: {id: nil}})
  end

  def error_facilities(facilities)
    facilities
      .joins(:cphc_migration_error_logs)
      .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
      .where("cphc_migration_audit_logs.id is null")
      .distinct(:facility_id)
  end

  def migration_summary(facilities, region_type)
    patients = Patient.where(assigned_facility_id: facilities)
    group_by_columns = {
      facility: "facilities.id",
      district: "facilities.district",
      state: "facilities.state"
    }.with_indifferent_access
    group_by_column = group_by_columns[region_type]

    {
      total: {
        patients: patients.joins(:assigned_facility).group(group_by_column).count,
        encounters: Encounter.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).group(group_by_column).count,
        blood_pressures: BloodPressure.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).group(group_by_column).count,
        blood_sugars: BloodSugar.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).group(group_by_column).count,
        prescription_drugs: PrescriptionDrug.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).group(group_by_column).count,
        appointments: Appointment.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).group(group_by_column).count
      },
      migrated:
        CphcMigrationAuditLog.where(facility_id: facilities)
          .joins(:facility)
          .group(:cphc_migratable_type, group_by_column)
          .count,
      errors:
        CphcMigrationErrorLog
          .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
          .joins(:facility)
          .where("cphc_migration_audit_logs.id is null")
          .where(facility_id: facilities)
          .group(:cphc_migratable_type, group_by_column)
          .count,
      daily:
        CphcMigrationAuditLog
          .joins(:facility)
          .group(:cphc_migratable_type, group_by_column)
          .group_by_period(:day, :created_at)
          .count
          .each_with_object({}) { |((model, region_id, date), count), result|
            result[date] ||= {}
            result[date][[model, region_id]] = count
          }
    }
  end

  def render_only_in_india
    fail_request(:unauthorized, "only allowed in India") unless CountryConfig.current_country?("India")
  end

  def ongoing_migrations
    Sidekiq::Queue.new("cphc_migration").size + Sidekiq::ScheduledSet.new.count { |job| job.queue == "cphc_migration" }
  end

  def region_summary(region)
    facilities = region.facilities
    patients = region.assigned_patients

    totals = {
      "Patient" => patients.joins(:assigned_facility).count,
      "Encounter" => Encounter.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).count,
      "BloodPressure" => BloodPressure.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).count,
      "BloodSugar" => BloodSugar.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).count,
      "PrescriptionDrug" => PrescriptionDrug.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).count,
      "Appointment" => Appointment.joins(:patient).joins(patient: :assigned_facility).where(patient_id: patients).count
    }

    migrated = CphcMigrationAuditLog.where(facility: facilities)
      .joins(:facility)
      .group(:cphc_migratable_type)
      .count

    errors = CphcMigrationErrorLog
      .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
      .joins(:facility)
      .where("cphc_migration_audit_logs.id is null")
      .where(facility_id: facilities)
      .group(:cphc_migratable_type)
      .count

    {totals: totals,
     migrated: migrated,
     errors: errors,
     mapped_facilities: mapped_facilities(region).count,
     unmapped_facilities: unmapped_facilities(region).count}
  end

  def child_summary(region)
    facilities = region.facilities
    patients = region.assigned_patients
    group_by_columns = {
      facility: "facilities.name",
      block: "facilities.block",
      district: "facilities.district",
      state: "facilities.state"
    }.with_indifferent_access
    group_by_column = group_by_columns[region.child_region_type]

    totals = patients.joins(:assigned_facility).group(group_by_column).count
    migrated = CphcMigrationAuditLog.where(facility: facilities)
      .joins(:facility)
      .where(cphc_migratable_type: "Patient")
      .group(group_by_column)
      .count

    errors = CphcMigrationErrorLog
      .joins("left outer join cphc_migration_audit_logs on cphc_migration_audit_logs.cphc_migratable_id = cphc_migration_error_logs.cphc_migratable_id")
      .joins(:facility)
      .where("cphc_migration_audit_logs.id is null")
      .where(facility_id: facilities)
      .distinct(:patient_id)
      .group(group_by_column)
      .count

    mapped_facilities = mapped_facilities(region).group(group_by_column).distinct("facilities.id").count
    unmapped_facilities = unmapped_facilities(region).group(group_by_column).distinct("facilities.id").count

    region.children.map do |child|
      [child.slug, {
        totals: totals[child.name],
        migrated: migrated[child.name],
        errors: errors[child.name],
        mapped_facilities: mapped_facilities[child.name],
        unmapped_facilities: unmapped_facilities[child.name],
        progress: {
          migrated: percentage(migrated[child.name], totals[child.name]),
          errors: percentage(errors[child.name], totals[child.name])
        }
      }]
    end.to_h
  end

  def migratable_region?(region)
    MIGRATABLE_REGIONS.include?(region.region_type.to_s)
  end
end
