class Admin::DeduplicatePatientsController < AdminController
  skip_before_action :verify_authenticity_token
  DUPLICATE_LIMIT = 250

  def show
    facilities = current_admin.accessible_facilities(:manage)
    authorize { facilities.any? }

    # Scoping by facilities is costly for users who have a lot of facilities
    duplicate_patient_ids = if current_admin.accessible_organizations(:manage).any?
      PatientDeduplication::Strategies.identifier_excluding_full_name_match(limit: DUPLICATE_LIMIT)
    else
      PatientDeduplication::Strategies.identifier_excluding_full_name_match_for_facilities(
        limit: DUPLICATE_LIMIT,
        facilities: facilities
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
end
