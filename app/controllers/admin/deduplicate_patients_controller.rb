class Admin::DeduplicatePatientsController < AdminController
  skip_before_action :verify_authenticity_token

  def show
    authorize { current_admin.power_user? }

    @patients = PatientSummary.where(id: Patient.take(5))
  end

  def merge
    authorize { current_admin.power_user? }

    duplicate_patients = Patient.where(id: params[:duplicate_patients])
    deduped_patient = DeduplicatePatients.new(duplicate_patients).merge

    redirect_to admin_deduplicate_patients_path, notice: "Patient merged into #{deduped_patient.id}"
  end
end
