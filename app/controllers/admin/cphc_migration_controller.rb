class Admin::CphcMigrationController < AdminController
  include SearchHelper
  include Pagination

  before_action :render_only_in_india
  helper_method :get_migrated_records
  helper_method :migratable_patients
  helper_method :unmapped_facilities
  helper_method :error_facilities
  helper_method :migration_summary

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

    @unmapped_facility_counts = unmapped_facilities(Facility.where(facility_group: facility_groups)).group(:facility_group_id).count
    @error_counts = error_facilities(Facility.where(facility_group: facility_groups)).group(:facility_group_id).count
    @district_results = migration_summary(Facility.where(facility_group: facility_group_ids), :district)
    @ongoing_migrations = ongoing_migrations
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

    @total_unmapped_facilities_count = unmapped_facilities(@facility_group.facilities).count
    @total_error_facilities_count = error_facilities(@facility_group.facilities).count

    @mappings = facility_mappings.group_by(&:facility_id)

    @unmapped_cphc_facilities = unmapped_facilities(@facility_group.facilities)

    @facility_results = migration_summary(@facilities, :facility)
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

  def update_facility_credentials
    authorize { current_admin.power_user? }

    facility = Facility.find_by!(slug: params.require(:facility_slug))
    facility.cphc_facility_mappings.presence.map { |mapping|
      mapping.auth_token = params[:user_authorization]
      mapping.cphc_user_details = {
        user_id: params[:user_id],
        facility_type_id: params[:facility_type_id],
        state_code: params[:state_code]
      }
      mapping.save!
    }

    redirect_to request.referrer, notice: "CPHC Facility #{facility.name} credentials updated"
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

  def cancel
    authorize { current_admin.power_user? }

    region = Region.find_by!(
      region_type: params.require(:region_type),
      slug: params.require(:region_slug)
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

  def unmapped_facilities(facilities)
    facilities
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
    }
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
    Sidekiq::Queue.new("cphc_migration").size + Sidekiq::ScheduledSet.new.select { |job| job.queue == "cphc_migration" }.size
  end
end
