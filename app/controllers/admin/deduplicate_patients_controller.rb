class Admin::DeduplicatePatientsController < AdminController
  skip_before_action :verify_authenticity_token
  DUPLICATE_LIMIT = 250

  def show
    authorize { current_admin.power_user? }

    duplicate_patient_ids = PatientDeduplication::Strategies.identifier_match(limit: DUPLICATE_LIMIT)
    @duplicate_count = duplicate_patient_ids.count
    @patients = Patient.where(id: duplicate_patient_ids.sample)
  end

  def merge
    authorize { current_admin.power_user? }

    duplicate_patients = Patient.where(id: params[:duplicate_patients])
    PatientDeduplication::Deduplicator.new(duplicate_patients, user: current_admin).merge

    redirect_to admin_deduplicate_patients_path, notice: "Patients merged"
  end
end
