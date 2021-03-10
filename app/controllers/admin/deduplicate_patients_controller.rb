class Admin::DeduplicatePatientsController < AdminController
  skip_before_action :verify_authenticity_token

  def show
    authorize { current_admin.power_user? }

    @patients = Patient.where(id: PatientDeduplication::Strategies.identifier_match(limit: 250).sample)
  end

  def merge
    authorize { current_admin.power_user? }

    duplicate_patients = Patient.where(id: params[:duplicate_patients])
    PatientDeduplication::Deduplicator.new(duplicate_patients).merge

    redirect_to admin_deduplicate_patients_path, notice: "Patients merged"
  end
end
