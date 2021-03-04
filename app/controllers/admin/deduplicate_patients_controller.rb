class Admin::DeduplicatePatientsController < AdminController
  skip_before_action :verify_authenticity_token

  def show
    authorize { current_admin.power_user? }

    @patients = Patient.where(id: duplicate_patient_ids)
  end

  def merge
    authorize { current_admin.power_user? }

    duplicate_patients = Patient.where(id: params[:duplicate_patients])
    deduped_patient = DeduplicatePatients.new(duplicate_patients).merge

    redirect_to admin_deduplicate_patients_path, notice: "Patient merged into #{deduped_patient.id}"
  end

  def duplicate_patient_ids
    identifier_type = PatientBusinessIdentifier.identifier_types[:simple_bp_passport]

    # This does an exact match based on case insensitive full name only.
    PatientBusinessIdentifier
      .select("identifier, array_agg(patient_id) as patient_ids")
      .where.not(identifier: "")
      .where(identifier_type: identifier_type)
      .group("identifier")
      .having("COUNT(distinct patient_id) > 1")
      .limit(250)
      .sample
      .patient_ids
  end
end
