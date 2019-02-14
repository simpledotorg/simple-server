class PatientsController < AdminController
  before_action :set_patient, only: [:edit, :update, :cancel]

  def index
    authorize Patient, :index?
    @patients_per_facility = policy_scope(Patient)
                               .not_contacted
                               .select { |patient| patient.blood_pressures.present? }
                               .group_by(&:registration_facility)
  end

  def edit
  end

  def cancel
  end

  def update
    if @patient.update(update_params)
      redirect_to patients_url, notice: 'Patient was successfully updated.'
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:id] || params[:patient_id])
    authorize @patient
  end

  def update_params
    params.require(:patient).permit(
      :contacted_by_counsellor,
      :could_not_contact_reason
    )
  end
end
