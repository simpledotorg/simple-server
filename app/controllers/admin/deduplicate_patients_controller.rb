class Admin::DeduplicatePatientsController < AdminController
  skip_before_action :verify_authenticity_token
  DUPLICATE_LIMIT = 250

  def show
    authorize { current_admin.power_user? }

    duplicate_patient_ids = PatientDeduplication::Strategies.identifier_excluding_full_name_match(limit: DUPLICATE_LIMIT)
    @duplicate_count = duplicate_patient_ids.count
    @patients = Patient.where(id: duplicate_patient_ids.sample)
  end

  def merge
    authorize { current_admin.power_user? }

    duplicate_patients = Patient.where(id: params[:duplicate_patients])
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
end
