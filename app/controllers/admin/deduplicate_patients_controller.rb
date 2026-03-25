class Admin::DeduplicatePatientsController < AdminController
  skip_before_action :verify_authenticity_token
  before_action :set_filter_options, only: [:show]
  DUPLICATE_LIMIT = 250

  def show
    facilities = current_admin.accessible_facilities(:manage)
    authorize { facilities.any? }

    # Apply facility filter if selected
    filtered_facilities = if @selected_facility.present?
      facilities.where(id: @selected_facility.id)
    elsif @selected_district.present?
      facilities.where(id: @selected_district.facilities)
    else
      facilities
    end

    # Scoping by facilities is costly for users who have a lot of facilities
    duplicate_patient_ids = if current_admin.accessible_organizations(:manage).any? && !@selected_district.present? && !@selected_facility.present?
      PatientDeduplication::Strategies.identifier_excluding_full_name_match(limit: DUPLICATE_LIMIT)
    else
      PatientDeduplication::Strategies.identifier_excluding_full_name_match_for_facilities(
        limit: DUPLICATE_LIMIT,
        facilities: filtered_facilities
      )
    end

    @duplicate_count = duplicate_patient_ids.count
    @patients = Patient.where(id: duplicate_patient_ids.sample).order(recorded_at: :asc)
  end

  def merge
    authorize { current_admin.accessible_facilities(:manage).any? }

    duplicate_patients = Patient.where(id: params[:duplicate_patients])
    return head :unauthorized unless can_admin_deduplicate_patients?(duplicate_patients)

    deduplicator = PatientDeduplication::Deduplicator.new(duplicate_patients, user: current_admin)
    merged_patient = deduplicator.merge

    if deduplicator.errors.present?
      PatientDeduplication::Stats.report("manual", duplicate_patients.count, 0, duplicate_patients.count)
      redirect_to admin_deduplication_path, alert: "Error in merging patients: #{deduplicator.errors.join(", ")}"
    else
      PatientDeduplication::Stats.report("manual", duplicate_patients.count, duplicate_patients.count, 0)
      redirect_to admin_deduplication_path, notice: "Patients merged into #{merged_patient.full_name}."
    end
  end

  def can_admin_deduplicate_patients?(patients)
    current_admin
      .accessible_facilities(:manage)
      .where(id: patients.pluck(:assigned_facility_id))
      .any?
  end

  private

  def set_filter_options
    @accessible_facilities = current_admin.accessible_facilities(:manage)
    populate_districts
    set_selected_district
    populate_facilities
    set_selected_facility
  end

  def populate_districts
    @districts = Region.district_regions
      .joins("INNER JOIN regions facility_region ON regions.path @> facility_region.path")
      .where("facility_region.source_id" => @accessible_facilities.map(&:id))
      .distinct(:slug)
      .order(:name)
  end

  def set_selected_district
    @selected_district = if params[:district_slug].present?
      @districts.find_by(slug: params[:district_slug])
    elsif @districts.present?
      @districts.first
    end
  end

  def populate_facilities
    @facilities = @accessible_facilities.where(id: @selected_district&.facilities).order(:name)
  end

  def set_selected_facility
    @selected_facility = @facilities.find_by(id: params[:facility_id]) if params[:facility_id].present?
  end
end
